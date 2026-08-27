module Api
  module V1
    module Accounts
      class CalendarController < Api::V1::Accounts::BaseController
        def index
          year = params[:year].presence || Date.current.year

          # Base: nacionales (account_id: nil) + propios de esta cuenta
          events = CalendarEvent
                     .for_year(year)
                     .for_account(Current.account.id)
                     .order(date: :asc)

          # Filtro por rango de fechas
          if params[:start_date].present? && params[:end_date].present?
            begin
              start_d = Date.parse(params[:start_date])
              end_d = Date.parse(params[:end_date])
              events = events.by_date_range(start_d, end_d)
            rescue ArgumentError
              return render json: { error: 'Formato de fecha inválido. Use YYYY-MM-DD' }, status: :bad_request
            end
          elsif params[:date].present?
            begin
              events = events.by_date(Date.parse(params[:date]))
            rescue ArgumentError
              return render json: { error: 'Formato de fecha inválido. Use YYYY-MM-DD' }, status: :bad_request
            end
          end

          # Filtro por tipo
          events = events.by_event_type(params[:event_type]) if params[:event_type].present?

          # Solo propios de esta cuenta (sin nacionales)
          if params[:own_only].to_s == 'true'
            events = events.where(account_id: Current.account.id)
          end

          render json: events
        end

        def create
          event = Current.account.calendar_events.new(event_params)
          event.year = event.date.year

          if event.save
            render json: event, status: :created
          else
            render json: { error: event.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          event = Current.account.calendar_events.find(params[:id])
          if event.update(event_params)
            render json: event
          else
            render json: { error: event.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          event = Current.account.calendar_events.find(params[:id])
          event.destroy
          head :ok
        end

        private

        def event_params
          params.require(:calendar_event).permit(
            :date, :name, :event_type, :description, :color, :bg, :border, :text_color, :label
          )
        end
      end
    end
  end
end
