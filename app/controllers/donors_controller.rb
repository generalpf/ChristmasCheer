class DonorsController < ApplicationController
  PAGE_SIZE = 50

  before_action :set_donor, only: %i[show edit update destroy]
  before_action :load_reference_collections, only: %i[new create edit update]

  def index
    @q = params[:q].to_s.strip
    scope = Donor.includes(:affiliate, :category, :courtesy_title, :city_town)
    if @q.present?
      pattern = "%#{Donor.sanitize_sql_like(@q)}%"
      scope = scope.where("last_name ILIKE :p OR company ILIKE :p", p: pattern)
    end
    scope = scope.order(Arel.sql("last_name ASC NULLS LAST, company ASC NULLS LAST, id ASC"))

    total = scope.count
    @total_pages = [ (total.to_f / PAGE_SIZE).ceil, 1 ].max
    @page = params[:page].to_i.clamp(1, @total_pages)
    @donors = scope.limit(PAGE_SIZE).offset((@page - 1) * PAGE_SIZE)
  end

  def show
  end

  def new
    @donor = Donor.new
  end

  def create
    @donor = Donor.new(donor_params)
    if @donor.save
      redirect_to @donor, notice: "Donor created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @donor.update(donor_params)
      redirect_to @donor, notice: "Donor updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @donor.destroy
    redirect_to donors_path, notice: "Donor deleted."
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to @donor, alert: "Cannot delete this donor: dependent records exist."
  end

  private
    def set_donor
      @donor = Donor.find(params[:id])
    end

    def load_reference_collections
      @affiliates = Affiliate.order(:name)
      @categories = Category.order(:name)
      @courtesy_titles = CourtesyTitle.order(:title)
      @city_towns = CityTown.order(:name)
    end

    def donor_params
      params.require(:donor).permit(
        :affiliate_id, :category_id, :courtesy_title_id, :city_town_id,
        :first_name, :spouse, :last_name, :job_title, :company,
        :address_line1, :address_line2, :province, :postal_code,
        :phone, :email1, :email2, :notes
      )
    end
end
