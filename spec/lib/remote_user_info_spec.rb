RSpec.describe RemoteUserInfo do
  let(:attribute_service_url) { "https://attribute-service" }

  let(:user) { FactoryBot.create(:user) }

  let(:bearer_token) { AccountManagerApplication.user_token(user.id).token }

  around do |example|
    ClimateControl.modify(ATTRIBUTE_SERVICE_URL: attribute_service_url) do
      example.run
    end
  end

  context "the attribute service is down" do
    before do
      stub_request(:get, "#{attribute_service_url}/oidc/user_info")
        .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" })
        .to_return(status: 500)
    end

    it "returns nil" do
      expect(described_class.call(user)).to be_nil
    end
  end

  context "the attribute service is up" do
    it "calls the attribute service" do
      attributes = { attribute: "value" }

      stub_request(:get, "#{attribute_service_url}/oidc/user_info")
        .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" })
        .to_return(body: attributes.to_json)

      expect(described_class.call(user)).to eq(attributes)
    end

    context "#update_profile!" do
      it "calls the attribute service to set the profile attributes" do
        email_stub = stub_request(:put, "#{attribute_service_url}/v1/attributes/email")
          .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" }, body: { value: user.email.to_json })
          .to_return(status: 200)
        email_verified_stub = stub_request(:put, "#{attribute_service_url}/v1/attributes/email_verified")
          .with(headers: { accept: "application/json", authorization: "Bearer #{bearer_token}" }, body: { value: user.confirmed?.to_json })
          .to_return(status: 200)

        described_class.new(user).update_profile!

        expect(email_stub).to have_been_made
        expect(email_verified_stub).to have_been_made
      end
    end
  end
end
