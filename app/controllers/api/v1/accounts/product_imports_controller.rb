module Api
  module V1
    module Accounts
      class ProductImportsController < Api::V1::Accounts::BaseController
        def create
          return render json: { error: 'No file' }, status: :bad_request if params[:file].blank?

          spreadsheet = Roo::Spreadsheet.open(params[:file].tempfile)
          sheet = spreadsheet.sheet(0)
          created = 0

          sheet.each_row_streaming(offset: 1) do |row|
            next if row.all?(&:blank?)
            product = Current.account.products.new(
              title: row[0]&.value.to_s,
              product_type: row[1]&.value.to_s.presence || 'Físico',
              stock: row[2]&.value.to_i || 0,
              cost: row[3]&.value.to_f || 0,
              price: row[4]&.value.to_f || 0,
              description: row[5]&.value.to_s,
              features: row[6]&.value.to_s,
              image_url: 'https://via.placeholder.com/40'
            )
            created += 1 if product.save
          end

          render json: { created: created }
        rescue => e
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end
    end
  end
end