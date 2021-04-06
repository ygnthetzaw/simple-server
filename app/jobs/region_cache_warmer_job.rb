class RegionCacheWarmerJob
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :default
  # sidekiq_throttle(concurrency: {limit: ENV["REGION_CACHE_WARMER_CONCURRENCY"] || DEFAULT_CONCURRENCY_LIMIT})

  def perform(region_id, period_attributes)
    region = Region.find(region_id)
    period = Period.new(period_attributes)
    RequestStore.store[:bust_cache] = true

    notify "starting region caching for region #{region_id}"
    # Reports::RegionService.call(region: region, period: period, with_exclusions: true)
    # Statsd.instance.increment("region_cache_warmer.with_exclusions.#{region.region_type}.cache")

    PatientBreakdownService.call(region: region, period: period)
    Statsd.instance.increment("patient_breakdown_service.#{region.region_type}.cache")
    notify "finished region caching for region #{region_id}"
  end

  private

  def notify(msg, extra = {})
    data = {
      logger: {
        name: self.class.name
      },
      class: self.class.name
    }.merge(extra).merge(msg: msg)
    Rails.logger.info data
  end
end
