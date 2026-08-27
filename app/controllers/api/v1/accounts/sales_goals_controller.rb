module Api
  module V1
    module Accounts
      class SalesGoalsController < Api::V1::Accounts::BaseController
        before_action :fetch_sales_goal, only: [:show, :update, :destroy]

        def index
          @sales_goals = Current.account.sales_goals.order(year: :desc, month: :desc)
          render json: @sales_goals
        end

        def show
          render json: @sales_goal
        end

        def current
          year  = params[:year]&.to_i  || Time.current.year
          month = params[:month]&.to_i || Time.current.month

          goal = Current.account.sales_goals.find_by(year: year, month: month)

          if goal
            render json: {
              id:       goal.id,
              year:     goal.year,
              month:    goal.month,
              amount:   goal.amount,
              currency: goal.currency
            }
          else
            render json: {
              year:     year,
              month:    month,
              amount:   0,
              currency: 'S/',
              message:  'No hay meta configurada para este mes'
            }
          end
        end

        # UPSERT: crea si no existe, actualiza si ya existe
        def create
          @sales_goal = Current.account.sales_goals.find_or_initialize_by(
            year:  sales_goal_params[:year],
            month: sales_goal_params[:month]
          )
          @sales_goal.assign_attributes(sales_goal_params)

          if @sales_goal.save
            status_code = @sales_goal.saved_change_to_attribute?(:id) ? :created : :ok
            render json: @sales_goal, status: status_code
          else
            render json: { error: @sales_goal.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @sales_goal.update(sales_goal_params)
            render json: @sales_goal
          else
            render json: { error: @sales_goal.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @sales_goal.destroy
          head :ok
        end

        private

        def fetch_sales_goal
          @sales_goal = Current.account.sales_goals.find(params[:id])
        end

        def sales_goal_params
          params.require(:sales_goal).permit(:year, :month, :amount, :currency)
        end
      end
    end
  end
end
