module Api
  module V1
    module Accounts
      class ProductsController < Api::V1::Accounts::BaseController
        before_action :fetch_product, only: [:show, :update, :destroy]

        def index
          @products = Current.account.products.order(created_at: :desc)
          render json: @products
        end

        def show; end

        def create
          @product = Current.account.products.new(product_params)
          if @product.save
            render json: @product, status: :created
          else
            render json: { error: @product.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @product.update(product_params)
            render json: @product
          else
            render json: { error: @product.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @product.destroy
          head :ok
        end

        # ← AÑADIR ESTO
        def import
          if params[:file].blank?
            return render json: { error: 'Archivo requerido' }, status: :bad_request
          end

          require 'roo'

          begin
            spreadsheet = Roo::Excelx.new(params[:file].path)
            header = spreadsheet.row(1)

            imported = 0
            errors = []

            (2..spreadsheet.last_row).each do |i|
              row = Hash[[header, spreadsheet.row(i)].transpose]

              product_data = {
                title: row['Título']&.to_s&.strip,
                product_type: row['Tipo']&.to_s&.strip,
                image_url: row['Imagen URL']&.to_s&.strip,
                description: row['Descripción']&.to_s&.strip,
                features: row['Características']&.to_s&.strip,
                stock: row['Stock'].to_i,
                cost: row['Costo (S/)'].to_f,
                price: row['Precio (S/)'].to_f
              }

              product = Current.account.products.new(product_data)

              if product.save
                imported += 1
              else
                errors << { row: i, message: product.errors.full_messages.join(', ') }
              end
            end

            render json: {
              message: "#{imported} productos importados",
              imported: imported,
              errors: errors,
              total: spreadsheet.last_row - 1
            }

          rescue => e
            render json: { error: "Error procesando Excel: #{e.message}" }, status: :unprocessable_entity
          end
        end

        private

        def fetch_product
          @product = Current.account.products.find(params[:id])
        end

        def product_params
          params.require(:product).permit(
            :title, :product_type, :description, :features,
            :image_url, :stock, :cost, :price
          )
        end
      end
    end
  end
end