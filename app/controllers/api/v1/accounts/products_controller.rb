module Api
  module V1
    module Accounts
      class ProductsController < Api::V1::Accounts::BaseController
        before_action :fetch_product, only: [:show, :update, :destroy]
        
        def index
          @products = Current.account.products.order(created_at: :desc)
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