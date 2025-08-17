# app/services/openai_receipt_extractor.rb
require "mini_magick"
require "base64"
require "shellwords"
require "json"
require "tmpdir"

class OpenaiReceiptExtractor
  # SOLO modelos con visión conocidos
  VISION_MODELS = %w[gpt-4o gpt-4o-mini gpt-4.1 gpt-4.1-mini].freeze

  # => { supplier:, rut:, date:, total:, items:[], raw_text: }
  def from_local_path(path, original_filename: nil)
    image_path = pdf?(path) ? to_png_first_page(path) : path

    data = File.open(image_path, "rb") { |f| f.read }
    data_url = "data:image/png;base64,#{Base64.strict_encode64(data)}"

    client = OpenAI::Client.new
    model  = pick_vision_model!(client) # ← ahora falla si no hay visión

    prompt = <<~TXT
      Eres un extractor de datos de boletas chilenas. Devuelve SOLO un objeto JSON con EXACTAMENTE estas claves:
      {
        "supplier": string|null,
        "rut": string|null,
        "date": "YYYY-MM-DD"|null,
        "total": number|null,
        "items": [
          { "name": string|null, "qty": number|null, "unit_price": number|null, "line_total": number|null }
        ],
        "raw_text": string|null
      }
      Reglas:
      - No inventes datos: si un dato no aparece claro, usa null (o "" si corresponde).
      - Los montos van como número (sin $ ni separadores de miles).
    TXT

    response = client.chat(
      parameters: {
        model: model,
        temperature: 0,
        max_tokens: 600,
        messages: [
          { role: "system", content: "Eres un asistente que extrae datos de comprobantes/boletas a JSON válido." },
          {
            role: "user",
            content: [
              { type: "text", text: prompt },
              { type: "image_url", image_url: { url: data_url } }
            ]
          }
        ],
        response_format: { type: "json_object" }
      }
    )

    json = safe_parse_content(response)
    normalize(json)
  rescue Faraday::BadRequestError => e
    body = e.response && e.response[:body] ? e.response[:body] : e.message
    raise "OpenAI 400: #{body}"
  end

  private

  def pick_vision_model!(client)
    available = client.models.list["data"].map { |m| m["id"] }
    model = (VISION_MODELS & available).first
    raise "No hay modelos con visión disponibles en tu proyecto (se necesita uno de: #{VISION_MODELS.join(', ')})." unless model
    model
  end

  def safe_parse_content(response)
    content = response.dig("choices", 0, "message", "content")
    JSON.parse(content)
  rescue => e
    raise "Respuesta no JSON: #{e.message} (preview: #{content&.byteslice(0, 200)})"
  end

  # Devuelve hash con defaults seguros para guardar
  def normalize(json)
    {
      supplier: json["supplier"].presence,
      rut:      json["rut"].presence,
      date:     json["date"].presence,
      total:    to_number_or_nil(json["total"]),
      items:    normalize_items(json["items"]),
      raw_text: json["raw_text"].to_s.presence
    }
  end

  def normalize_items(items)
    return [] unless items.is_a?(Array)
    items.map do |it|
      {
        "name"       => it["name"].to_s,
        "qty"        => to_number_or_nil(it["qty"]),
        "unit_price" => to_number_or_nil(it["unit_price"]),
        "line_total" => to_number_or_nil(it["line_total"])
      }
    end
  end

  def to_number_or_nil(v)
    return nil if v.nil? || v == ""
    v.is_a?(Numeric) ? v : Float(v) rescue nil
  end

  def pdf?(path)
    File.extname(path).downcase == ".pdf"
  end

  def to_png_first_page(pdf_path)
    out = File.join(Dir.tmpdir, "page")
    system("pdftoppm -png #{Shellwords.escape(pdf_path)} #{Shellwords.escape(out)}")
    png = Dir["#{out}-1.png"].first or raise "No se pudo convertir PDF a PNG"
    img = MiniMagick::Image.open(png)
    img.resize "2000x2000>"
    img.write(png)
    png
  end
end
