require 'spec_helper'

describe Kit::Bit::Assets do

  let(:config) do
    YAML.load <<-EOF
      :settings:
        :js_compressor: :uglifier
        :not_a_good_setting: :some_value
      :paths:
        - assets/javascripts
        - other/javascripts
    EOF
  end

  subject(:assets) { Kit::Bit::Assets.new }

  describe "#sprockets" do

    it "returns a new sprockets environment" do
      expect(assets.sprockets).to be_a Sprockets::Environment
    end
  end

  describe "#load_settings" do

    subject(:assets) { Kit::Bit::Assets.new settings: config[:settings] }

    it "sets the settings for sprockets" do
      expect(assets.sprockets).to receive(:js_compressor=).with(:uglifier)
      assets.load_settings
    end

    it "does not load an unset setting" do
      expect(assets.sprockets).to_not receive(:css_compressor)
      assets.load_settings
    end

    it "does not load an invalid setting" do
      expect(assets.sprockets).to_not receive(:not_a_good_setting)
      assets.load_settings
    end

    context "no settings" do

      it "does not fail when settings not set" do
        assets.settings = nil
        expect { assets.load_settings }.to_not raise_error
      end
    end
  end

  describe "#load_paths" do

    subject(:assets) { Kit::Bit::Assets.new paths: config[:paths] }

    context "when directory set" do

      it "loads the paths for the given set into the sprockets environment" do
        assets.directory = '/tmp/root_dir'
        expect(assets.sprockets).to receive(:append_path).with('/tmp/root_dir/assets/javascripts')
        expect(assets.sprockets).to receive(:append_path).with('/tmp/root_dir/other/javascripts')
        assets.load_paths
      end
    end

    context "when no directory set" do

      it "loads the paths for the given set into the sprockets environment" do
        expect(assets.sprockets).to receive(:append_path).with('assets/javascripts')
        expect(assets.sprockets).to receive(:append_path).with('other/javascripts')
        assets.load_paths
      end
    end

    context "when no paths set" do

      it "should not fail" do
        assets.paths = nil
        expect { assets.load_paths }.to_not raise_error
      end
    end
  end

  describe "#assets" do

    subject(:assets) { Kit::Bit::Assets.new paths: config[:paths] }

    it "should load settings" do
      expect(assets).to receive :load_settings
      assets.assets
    end

    it "should load paths" do
      expect(assets).to receive :load_paths
      assets.assets
    end

    it "should return compiled assets" do
      expect(assets.assets).to equal assets.sprockets
    end
  end
end
