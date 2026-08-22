module Api
  module V1
    module Accounts
      class OrdersController < Api::V1::Accounts::BaseController
        before_action :fetch_order, only: [:show, :update, :destroy]

        def index
          @orders = Current.account.orders.order(created_at: :desc)

          # Filtros
          @orders = @orders.by_status(params[:status]) if params[:status].present?
          @orders = @orders.by_created_date(params[:created_date]) if params[:created_date].present?

          # Búsqueda por texto
          if params[:q].present?
            q = "%#{params[:q]}%"
            @orders = @orders.where(
              'order_number ILIKE ? OR customer_name ILIKE ? OR customer_phone ILIKE ?',
              q, q, q
            )
          end

          render json: @orders
        end

        def show
          render json: @order
        end

        def create
          @order = Current.account.orders.new(order_params)
          if @order.save
            render json: @order, status: :created
          else
            render json: { error: @order.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @order.update(order_params)
            render json: @order
          else
            render json: { error: @order.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @order.destroy
          head :ok
        end

        private

        def fetch_order
          @order = Current.account.orders.find(params[:id])
        end

        def order_params
          params.require(:order).permit(
            :contact_id, :inbox_id, :status, :delivery_type,
            :delivery_date, :delivery_hour, :delivery_address, :delivery_reference,
            :customer_name, :customer_phone, :customer_email,
            :total_amount, :items_json, :notes
          )
        end
      end
    end
  end
end
