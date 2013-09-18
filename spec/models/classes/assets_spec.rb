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
        assets.settings = {}
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
        assets.paths = {}
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

    it "should not load settings and paths twice" do
      expect(assets).to receive(:load_settings).once
      expect(assets).to receive(:load_paths).once
      assets.assets
      assets.assets
    end

    it "should return compiled assets" do
      expect(assets.assets).to equal assets.sprockets
    end
  end

  describe "#write" do

    let(:asset) { double Sprockets::Asset }
    let(:source) { %q{alert('test')} }
    let(:hash) { Digest::SHA1.hexdigest source }
    let(:name) { "app-#{hash}.js" }

    before :each do
      assets.assets.stub(:[]).with('app').and_return(asset)
      asset.stub(:to_s).and_return(source)
      asset.stub(:logical_path).and_return('app.js')
    end

    context "path is given with no directory" do

      it "writes to relative path" do
        expect(asset).to receive(:write_to).with("tmp/path/#{name}")
        assets.write 'app', path: 'tmp/path'
      end

      it "writes to absolute path" do
        expect(asset).to receive(:write_to).with("/tmp/path/#{name}")
        assets.write 'app', path: '/tmp/path'
      end
    end

    context "path is given with directory" do

      it "writes to relative path under directory" do
        assets.directory = '/tmp/dir'
        expect(asset).to receive(:write_to).with("/tmp/dir/path/#{name}")
        assets.write 'app', path: 'path'
      end

      it "writes to absolute path" do
        assets.directory = '/tmp/dir'
        expect(asset).to receive(:write_to).with("/tmp/path/#{name}")
        assets.write 'app', path: '/tmp/path'
      end
    end

    context "no path is given with directory" do
      it "writes to relative path under directory" do
        assets.directory = '/tmp/dir'
        expect(asset).to receive(:write_to).with("/tmp/dir/#{name}")
        assets.write 'app'
      end
    end

    context "no path is given with no directory" do
      it "writes to relative path" do
        expect(asset).to receive(:write_to).with(name)
        assets.write 'app'
      end
    end

    context "when gzip true" do

      it "appends .gz to the path" do
        asset.stub(:write_to)
        expect(assets.write 'app', gzip: true).to eq "#{name}.gz"
      end

      it "it gzips the assets" do
        expect(asset).to receive(:write_to).with("#{name}.gz", compress: true)
        assets.write 'app', gzip: true
      end
    end
  end
end
