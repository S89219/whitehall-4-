require 'test_helper'
require 'gds_api/test_helpers/publishing_api_v2'

class PublishingApiRedirectWorkerTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::PublishingApiV2

  setup do
    @uuid = SecureRandom.uuid
    @base_path = "/government/this-needs-redirecting.fr"

    @destination = "/government/has-been-redirected.fr"
  end

  test "unpublished the item as a 'redirect' for the supplied content_id" do
    request = stub_publishing_api_unpublish(
      @uuid,
      body: {
        type: 'redirect',
        locale: 'fr',
        alternative_path: @destination,
      }
    )

    PublishingApiRedirectWorker.new.perform(@uuid, @destination, "fr")

    assert_requested request
  end

  test "passes allow_draft if it is supplied" do
    request = stub_publishing_api_unpublish(
      @uuid,
      body: {
        type: 'redirect',
        locale: 'fr',
        alternative_path: @destination,
        allow_draft: true,
      }
    )

    PublishingApiRedirectWorker.new.perform(@uuid, @destination, "fr", true)

    assert_requested request
  end

  test "trims the destination url" do
    @destination = "/government/has-been-redirected.fr "
    request = stub_publishing_api_unpublish(
      @uuid,
      body: {
        type: 'redirect',
        locale: 'fr',
        alternative_path: "/government/has-been-redirected.fr",
        allow_draft: true,
      }
    )

    PublishingApiRedirectWorker.new.perform(@uuid, @destination, "fr", true)

    assert_requested request
  end
end
