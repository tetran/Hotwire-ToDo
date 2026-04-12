module Paginatable
  extend ActiveSupport::Concern

  included do
    include Pagy::Backend
  end

  private

    def paginate(collection)
      pagy(collection, limit: per_page_param)
    end

    def pagination_meta(pagy)
      {
        page: pagy.page,
        per_page: pagy.limit,
        total_count: pagy.count,
        total_pages: pagy.pages,
      }
    end

    def per_page_param
      params.fetch(:per_page, 25).to_i.clamp(1, 100)
    end
end
