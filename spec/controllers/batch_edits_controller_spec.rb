require 'spec_helper'

describe BatchEditsController, :type => :controller do
  before do
    allow(controller).to receive(:has_access?).and_return(true)
    @user = FactoryGirl.find_or_create(:jill)
    sign_in @user
    allow_any_instance_of(User).to receive(:groups).and_return([])
    allow(controller).to receive(:clear_session_user) ## Don't clear out the authenticated session
    request.env["HTTP_REFERER"] = 'test.host/original_page'
  end

  routes { Internal::Application.routes }

  describe "edit" do
    before do
      @one = GenericFile.new(creator: ["Fred"], language: ['en'])
      @one.apply_depositor_metadata('mjg36')
      @two = GenericFile.new(creator: ["Wilma"], publisher: ['Rand McNally'], language: ['en'], resource_type: ['bar'])
      @two.apply_depositor_metadata('mjg36')
      @one.save!
      @two.save!
      controller.batch = [@one.pid, @two.pid]
      expect(controller).to receive(:can?).with(:edit, @one.pid).and_return(true)
      expect(controller).to receive(:can?).with(:edit, @two.pid).and_return(true)
    end
    it "should be successful" do
      get :edit
      expect(response).to be_successful
      expect(assigns[:terms]).to eq([:creator, :contributor, :description, :tag, :rights, :publisher,
                        :date_created, :subject, :language, :identifier, :based_near, :related_url])
      expect(assigns[:show_file].creator).to eq ["Fred", "Wilma"]
      expect(assigns[:show_file].publisher).to eq ["Rand McNally"]
      expect(assigns[:show_file].language).to eq ["en"]
    end
    it "should set the breadcrumb trail" do
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
      get :edit
    end
  end

  describe "update" do
    before do
      @one = GenericFile.new(creator: ["Fred"], language: ['en'])
      @one.apply_depositor_metadata('mjg36')
      @two = GenericFile.new(creator: ["Wilma"], publisher: ['Rand McNally'], language: ['en'])
      @two.apply_depositor_metadata('mjg36')
      @one.save!
      @two.save!
      controller.batch = [@one.pid, @two.pid]
      expect(controller).to receive(:can?).with(:edit, @one.pid).and_return(true)
      expect(controller).to receive(:can?).with(:edit, @two.pid).and_return(true)
    end
    let(:mycontroller) { "my/files" }
    it "should be successful" do
      put :update , update_type: "delete_all"
      expect(response).to redirect_to(Sufia::Engine.routes.url_for(controller: "dashboard", only_path: true))
      expect { GenericFile.find(@one.id) }.to raise_error(ActiveFedora::ObjectNotFoundError)
      expect { GenericFile.find(@two.id) }.to raise_error(ActiveFedora::ObjectNotFoundError)
    end
    it "should redirect to the return controller" do
      put :update , update_type: "delete_all", return_controller: mycontroller
      expect(response).to redirect_to(Sufia::Engine.routes.url_for(controller: mycontroller, only_path: true))
    end
    it "should update the records" do
      put :update , update_type: "update", "generic_file"=>{"subject"=>["zzz"]}
      expect(response).to be_redirect
      expect(GenericFile.find(@one.id).subject).to eq ["zzz"]
      expect(GenericFile.find(@two.id).subject).to eq ["zzz"]
    end
  end

end
