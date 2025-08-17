# app/controllers/purchases_controller.rb
class PurchasesController < ApplicationController
  before_action :set_purchase, only: [:show, :edit, :update, :destroy]

  # GET /purchases
  def index
    @q     = params[:q].to_s.strip.presence
    @from  = params[:from].presence
    @to    = params[:to].presence

    scope = build_scope
    @purchases = scope.order(date: :desc, created_at: :desc).limit(200)
    @total_sum = @purchases.sum(:total)
  end

  # GET /
  def new
    @purchase = Purchase.new
  end

  # POST /purchases/preview
  # Sube archivo → IA extrae → muestra form precargado (NO guarda)
  def preview
    uploaded = params.require(:document)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: uploaded.tempfile,
      filename: uploaded.original_filename,
      content_type: uploaded.content_type
    )

    Rails.logger.debug("Starting OpenAI extraction for file: #{uploaded.tempfile.path}")
    result = OpenaiReceiptExtractor.new.from_local_path(
      uploaded.tempfile.path,
      original_filename: uploaded.original_filename
    )

    @purchase = Purchase.new(
      supplier: result[:supplier],
      rut:      result[:rut],
      date:     result[:date],
      total:    result[:total],
      items:    result[:items],
      raw_text: result[:raw_text]
    )
    Rails.logger.debug("OpenAI extraction result: #{result.inspect}")

    if [@purchase.supplier, @purchase.rut, @purchase.date, @purchase.total].all?(&:blank?) &&
       (@purchase.items.blank? || @purchase.items == [])
      flash.now[:alert] = "No se pudo extraer información automáticamente. Completa y guarda, o reintenta con otra foto."
    end

    @document_signed_id = blob.signed_id
    Rails.logger.debug("Purchase object before rendering: #{@purchase.inspect}")
    render :new, status: :ok
  rescue => e
    Rails.logger.error("OpenAI extraction failed: #{e.class} #{e.message}")
    Rails.logger.debug("Backtrace: #{e.backtrace.join("\n")}")
    flash.now[:alert] = "No se pudo procesar la boleta: #{e.message.to_s.truncate(180)}"
    @purchase = Purchase.new
    render :new, status: :unprocessable_content
  end

  # POST /purchases
  def create
    @purchase = Purchase.new(purchase_params.except(:items_json))

    if purchase_params[:items_json].present?
      @purchase.items = JSON.parse(purchase_params[:items_json]) rescue []
    end

    if params[:document_signed_id].present?
      @purchase.document.attach(params[:document_signed_id])
    elsif params.dig(:purchase, :document).present?
      @purchase.document.attach(params[:purchase][:document])
    end

    if @purchase.save
      redirect_to @purchase, notice: "Boleta guardada."
    else
      flash.now[:alert] = @purchase.errors.full_messages.to_sentence
      render :new, status: :unprocessable_content
    end
  end

  # GET /purchases/:id
  def show; end

  # GET /purchases/:id/edit
  def edit; end

  # PATCH/PUT /purchases/:id
  def update
    attrs = purchase_params.except(:items_json)

    if purchase_params[:items_json].present?
      attrs[:items] = JSON.parse(purchase_params[:items_json]) rescue @purchase.items
    end

    if @purchase.update(attrs)
      redirect_to @purchase, notice: "Boleta actualizada."
    else
      flash.now[:alert] = @purchase.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /purchases/:id
  def destroy
    @purchase.destroy
    redirect_to purchases_path, notice: "Boleta eliminada."
  end

  # DELETE /purchases/destroy_all
  def destroy_all
    count = Purchase.count
    Purchase.find_each(&:destroy)
    redirect_to purchases_path, notice: "Se eliminaron #{count} boletas."
  end

  # DELETE /purchases/destroy_filtered
  def destroy_filtered
    scope = build_scope
    count = scope.count
    scope.find_each(&:destroy)
    redirect_to purchases_path, notice: "Se eliminaron #{count} boletas (filtradas)."
  end

  private

  def set_purchase
    @purchase = Purchase.find(params[:id])
  end

  def purchase_params
    params.require(:purchase).permit(
      :supplier,
      :rut,
      :date,
      :total,
      :raw_text,
      :document,
      :items_json
    )
  end

  # Reutiliza la lógica de filtros
  def build_scope
    scope = Purchase.all
    q    = params[:q].to_s.strip.presence
    from = params[:from].presence
    to   = params[:to].presence

    if q
      scope = scope.where("supplier ILIKE :q OR rut ILIKE :q OR raw_text ILIKE :q", q: "%#{q}%")
    end
    scope = scope.where("date >= ?", from) if from
    scope = scope.where("date <= ?", to)   if to
    scope
  end
end
