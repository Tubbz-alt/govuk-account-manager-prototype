RSpec.describe "feedback" do
  describe "GET" do
    it "renders the form" do
      get feedback_form_path

      expect(response.body).to have_content(I18n.t("feedback.show.heading"))
    end

    context "when user is logged in" do
      let(:user) { FactoryBot.create(:user) }

      before do
        sign_in(user)
      end

      it "pre-populates the email field" do
        get feedback_form_path

        expect(response.body).to have_selector("input[name='email'][value='#{user.email}']")
      end
    end
  end

  describe "POST" do
    context "when user wants a response" do
      let(:params) do
        {
          "name" => "A Person",
          "email" => "user@digital.cabinet-office.gov.uk",
          "comments" => "This website is amazing",
          "user_requires_response" => "yes",
        }
      end

      let(:ticket_attributes) do
        {
          subject: I18n.t("feedback.show.email_subject"),
          name: params["name"],
          email: params["email"],
          comments: params["comments"],
          user_requires_response: params["user_requires_response"].humanize,
        }
      end

      context "when all required fields are present" do
        it "queues a worker" do
          expect(ZendeskTicketJob).to receive(:perform_later).once.with(ticket_attributes)

          post feedback_form_path, params: params
        end
      end

      context "when required fields are missing" do
        %w[comments name email user_requires_response].each do |field|
          it "shows an error when required field #{field} is missing" do
            post feedback_form_path, params: params.except(field)

            expect(response.body).to have_content(I18n.t("feedback.show.fields.#{field}.not_present_error"))
          end
        end

        it "replays sanitized response for name" do
          post feedback_form_path, params: { user_requires_response: "yes", name: "<script>alert()</script>A Person" }

          expect(response.body).to have_selector("input[name='name'][value='A Person']")
        end

        it "replays sanitized response for email" do
          post feedback_form_path, params: { user_requires_response: "yes", email: "<script>alert()</script>abc@digital.cabinet-office.gov.uk" }

          expect(response.body).to have_selector("input[name='email'][value='abc@digital.cabinet-office.gov.uk']")
        end

        it "replays sanitized response for comments" do
          post feedback_form_path, params: { user_requires_response: "yes", comments: "<script>alert()</script>Some text" }

          expect(response.body).to have_selector("textarea[name='comments']", text: "Some text")
        end

        it "replays the response for response required" do
          post feedback_form_path, params: { user_requires_response: "yes" }

          expect(response.body).to have_selector("input[name='user_requires_response'][value='yes'][checked=checked]")
        end
      end
    end

    context "when user does not want a response" do
      let(:params) do
        {
          "name" => "",
          "email" => "",
          "comments" => "This website is amazing",
          "user_requires_response" => "no",
        }
      end

      let(:ticket_attributes) do
        {
          subject: I18n.t("feedback.show.email_subject"),
          name: I18n.t("feedback.show.anonymous_name"),
          email: I18n.t("feedback.show.anonymous_email"),
          comments: params["comments"],
          user_requires_response: params["user_requires_response"].humanize,
        }
      end

      context "when all required fields are present" do
        it "queues a job" do
          expect(ZendeskTicketJob).to receive(:perform_later).once.with(ticket_attributes)

          post feedback_form_path, params: params
        end
      end

      context "when required fields are missing" do
        %w[comments user_requires_response].each do |field|
          it "shows an error when required field #{field} is missing" do
            post feedback_form_path, params: params.except(field)

            expect(response.body).to have_content(I18n.t("feedback.show.fields.#{field}.not_present_error"))
          end
        end

        it "replays sanitized response for comments" do
          post feedback_form_path, params: { comments: "<script>alert()</script>Some text" }

          expect(response.body).to have_selector("textarea[name='comments']", text: "Some text")
        end

        it "replays the response for response not required" do
          post feedback_form_path, params: { user_requires_response: "no" }

          expect(response.body).to have_selector("input[name='user_requires_response'][value='no'][checked=checked]")
        end
      end
    end
  end
end
