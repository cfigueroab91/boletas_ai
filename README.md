# 📄 Gestor de Compras con Rails + OpenAI

## Descripción del Proyecto

El **Gestor de Compras** es una aplicación robusta construida con **Ruby on Rails 7** que optimiza la gestión de boletas y facturas de compra. Aprovechando el poder de **OpenAI**, esta aplicación automatiza la extracción de información clave de los documentos subidos, eliminando la necesidad de servicios OCR externos. Los usuarios pueden subir fácilmente boletas en formato **PDF o imagen**, y la aplicación procesará automáticamente y prellenará un formulario con detalles esenciales como el proveedor, RUT, fecha, monto total e ítems. La aplicación también permite a los usuarios editar y guardar los detalles de las compras en una base de datos **PostgreSQL**, y ofrece potentes capacidades de búsqueda y filtrado.

## Características

- **Subir y Procesar Boletas**: Soporta la subida de boletas en formato PDF o imagen, que son procesadas usando OpenAI.
- **Extracción Automática de Datos**: Extrae y prellena automáticamente formularios con detalles de proveedor, RUT, fecha, total e ítems.
- **Editar y Guardar Compras**: Permite editar y guardar los detalles de las compras en una base de datos PostgreSQL.
- **Buscar y Filtrar**: Ofrece opciones de búsqueda y filtrado por proveedor, RUT, rango de fechas o texto.
- **Opciones de Eliminación**: Ofrece la posibilidad de eliminar una boleta individual, todas las boletas, o solo las boletas filtradas con un modal de confirmación.

## 🚀 Requisitos

Para ejecutar la aplicación **Gestor de Compras**, asegúrate de que tu entorno cumpla con los siguientes requisitos:

- **Ruby**: Versión 3.2 o superior
- **Rails**: Versión 7 o superior
- **PostgreSQL**: Versión 14 o superior
- **Node.js**: Requerido para la gestión de activos
- **Yarn**: Requerido para gestionar dependencias de JavaScript
- **Cuenta de OpenAI**: Una cuenta activa de OpenAI con la variable de entorno `OPENAI_API_KEY` configurada

## ⚙️ Instalación

Sigue estos pasos para configurar la aplicación **Gestor de Compras**:

1. **Clonar el Repositorio**:
   ```bash
   git clone https://github.com/cfigueroab91/boletas_ai.git
   cd boletas_ai
   ```

2. **Instalar Dependencias**:
   ```bash
   bundle install
   yarn install
   ```

3. **Crear y Migrar la Base de Datos**:
   ```bash
   rails db:create db:migrate
   ```

4. **Configurar la Variable de Entorno de OpenAI**:
   ```bash
   echo "OPENAI_API_KEY=sk-xxxx" > .env
   ```
   *(Si estás usando dotenv-rails, esto se cargará automáticamente)*

5. **Iniciar el Servidor**:
   ```bash
   bin/rails s
   ```

## 🖥️ Uso

1. **Acceder a la Aplicación**:
   - Abre tu navegador web y navega a `http://localhost:3000/`.

2. **Subir una Boleta**:
   - Haz clic en la opción para subir una boleta.
   - La boleta será procesada usando OpenAI, y un formulario será prellenado con los datos extraídos.

3. **Revisar y Editar**:
   - Revisa el formulario prellenado.
   - Realiza las ediciones necesarias en los datos.
   - Guarda los detalles de la compra en la base de datos.

4. **Gestionar Compras**:
   - Navega a la sección "Compras" para ver y gestionar tus compras.
   - Usa las opciones de búsqueda y filtrado para encontrar compras específicas por proveedor, RUT, rango de fechas o texto.

5. **Realizar Acciones**:
   - Ver, editar o eliminar boletas individuales.
   - Usa la opción "Eliminar TODO" para eliminar todas las boletas.
   - Usa la opción "Eliminar filtrados" para eliminar solo las boletas filtradas.
   - Confirma las eliminaciones a través de un modal personalizado.

## 📂 Estructura del Proyecto

Aquí tienes una breve descripción de las partes relevantes de la estructura del proyecto **Gestor de Compras**:

```plaintext
app/
 ├── controllers/
 │    └── purchases_controller.rb   # Lógica principal para gestionar compras
 ├── models/
 │    └── purchase.rb               # Modelo de compra con ActiveStorage e ítems en JSON
 ├── views/purchases/
 │    ├── index.html.erb            # Vista de lista con filtros y modal
 │    ├── new.html.erb              # Subida y vista previa de IA
 │    └── show.html.erb             # Vista detallada de una compra
 └── services/
      └── openai_receipt_extractor.rb  # Lógica de extracción de IA
```

- **Controladores**: Manejan la lógica principal para gestionar compras.
- **Modelos**: Definen la estructura de datos y relaciones para las compras.
- **Vistas**: Contienen los componentes de la interfaz de usuario para mostrar e interactuar con las compras.
- **Servicios**: Incluyen la lógica para extraer datos de las boletas usando OpenAI.
