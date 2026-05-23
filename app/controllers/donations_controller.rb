class DonationsController < ApplicationController
  PAGE_SIZE = 50

  before_action :set_donor_from_nested_route, only: %i[index new create]
  before_action :set_donation, only: %i[show edit update destroy]
  before_action :load_donors_for_select, only: %i[edit update]

  def index
    @q = params[:q].to_s.strip
    @year = year_param

    scope = Donation.includes(:donor)
    scope = @donor ? @donor.donations.includes(:donor) : scope
    if @year
      from = Date.new(@year, 1, 1)
      to = Date.new(@year + 1, 1, 1)
      scope = scope.where("donation_date >= ? AND donation_date < ?", from, to)
    end
    if @donor.nil? && @q.present?
      pattern = "%#{Donor.sanitize_sql_like(@q)}%"
      scope = scope.joins(:donor).where(
        "donors.last_name ILIKE :p OR donors.company ILIKE :p", p: pattern
      )
    end
    scope = scope.order(Arel.sql("donation_date DESC NULLS LAST, donations.id DESC"))

    @available_years = Donation.where.not(donation_date: nil)
      .distinct
      .pluck(Arel.sql("EXTRACT(YEAR FROM donation_date)::int"))
      .compact
      .sort
      .reverse

    total = scope.count
    @total_pages = [ (total.to_f / PAGE_SIZE).ceil, 1 ].max
    @page = params[:page].to_i.clamp(1, @total_pages)
    @donations = scope.limit(PAGE_SIZE).offset((@page - 1) * PAGE_SIZE)
  end

  def show
  end

  def new
    @donation = (@donor ? @donor.donations.new : Donation.new)
    load_donors_for_select unless @donor
  end

  def create
    @donation =
      if @donor
        @donor.donations.new(donation_params.except(:donor_id))
      else
        Donation.new(donation_params)
      end

    if @donation.save
      redirect_to donation_path(@donation), notice: "Donation recorded."
    else
      load_donors_for_select unless @donor
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @donation.update(donation_params)
      redirect_to donation_path(@donation), notice: "Donation updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    referer = request.referer.to_s
    donor = @donation.donor
    @donation.destroy
    if donor && referer.include?(donor_donations_path(donor))
      redirect_to donor_donations_path(donor), notice: "Donation deleted."
    else
      redirect_to donations_path, notice: "Donation deleted."
    end
  end

  private
    def set_donor_from_nested_route
      @donor = Donor.find(params[:donor_id]) if params[:donor_id].present?
    end

    def set_donation
      @donation = Donation.find(params[:id])
    end

    def load_donors_for_select
      @donors_for_select = Donor.order(
        Arel.sql("last_name ASC NULLS LAST, company ASC NULLS LAST, id ASC")
      )
    end

    def year_param
      raw = params[:year].to_s.strip
      return nil if raw.empty?

      year = Integer(raw, 10) rescue nil
      year && year.positive? ? year : nil
    end

    def donation_params
      params.require(:donation).permit(
        :donor_id, :amount, :eligible_amount,
        :source_id, :payment_id, :publication_id,
        :transaction_reference, :message, :receipt_num,
        :donation_date, :receipt_date, :deposit_date,
        :c_receipt_num,
        :receipt_required, :receipt_pending, :receipt_processed, :receipt_replaced,
        :notes
      )
    end
end
