require 'spec_helper'

describe Kit::Bit::Assets do

  let(:config) do
    YAML.load <<-EOF
      :options:
        :js_compressor: :uglifier
        :not_a_good_setting: :some_value
      :paths:
        - assets/javascripts
        - other/javascripts
    EOF
  end

  subject(:assets) { Kit::Bit::Assets.new }

  describe ".new" do

    it "sets default options" do
      expect(assets.options).to eq Kit::Bit::Assets::DEFAULT_OPTIONS
    end

    it "merges default options" do
      assets = Kit::Bit::Assets.new options: { src_pre: '{{' }
      expect(assets.options).to eq Kit::Bit::Assets::DEFAULT_OPTIONS.merge(src_pre: '{{')
    end
  end

  describe "#options=" do

    it "merges with default options" do
      assets.options[:src_pre] = '{{'
      expect(assets.options).to eq Kit::Bit::Assets::DEFAULT_OPTIONS.merge(src_pre: '{{')
    end

    it "can be called twice and merge options" do
      assets.options[:src_pre] = '{{'
      assets.options[:src_post] = '}}'
      expect(assets.options).to eq Kit::Bit::Assets::DEFAULT_OPTIONS.merge(src_pre: '{{', src_post: '}}')
    end
  end

  describe "#sprockets" do

    it "returns a new sprockets environment" do
      expect(assets.sprockets).to be_a Sprockets::Environment
    end
  end

  describe "#load_options" do

    subject(:assets) { Kit::Bit::Assets.new options: config[:options] }

    it "sets the options for sprockets" do
      expect(assets.sprockets).to receive(:js_compressor=).with(:uglifier)
      assets.load_options
    end

    it "does not load an unset setting" do
      expect(assets.sprockets).to_not receive(:css_compressor)
      assets.load_options
    end

    it "does not load an invalid setting" do
      expect(assets.sprockets).to_not receive(:not_a_good_setting)
      assets.load_options
    end

    context "no options" do

      it "does not fail when options not set" do
        assets.options = {}
        expect { assets.load_options }.to_not raise_error
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

    it "should load options" do
      expect(assets).to receive :load_options
      assets.assets
    end

    it "should load paths" do
      expect(assets).to receive :load_paths
      assets.assets
    end

    it "should not load options and paths twice" do
      expect(assets).to receive(:load_options).once
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
    let(:name) { 'app.js' }

    before :each do
      assets.options = { hash: false }
      allow(assets.assets).to receive(:[]).with('app').and_return(asset)
      allow(asset).to receive(:to_s).and_return(source)
      allow(asset).to receive(:logical_path).and_return('app.js')
    end

    context "asset not found" do
      it "returns nil" do
        allow(assets.assets).to receive(:[]).with('not_here').and_return(nil)
        expect(assets.write 'not_here').to be nil
      end
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

      it "writes to relative path under directory and returns the hashed logical path" do
        assets.directory = '/tmp/dir'
        expect(asset).to receive(:write_to).with("/tmp/dir/path/#{name}")
        expect(assets.write 'app', path: 'path').to eq name
      end

      it "writes to absolute path and returns the hashed logical path" do
        assets.directory = '/tmp/dir'
        expect(asset).to receive(:write_to).with("/tmp/path/#{name}")
        expect(assets.write'app', path: '/tmp/path').to eq name
      end
    end

    context "no path is given with directory and returns the hashed logical path" do
      it "writes to relative path under directory" do
        assets.directory = '/tmp/dir'
        expect(asset).to receive(:write_to).with("/tmp/dir/#{name}")
        expect(assets.write 'app').to eq name
      end
    end

    context "no path is given with no directory" do
      it "writes to relative path" do
        expect(asset).to receive(:write_to).with(name)
        expect(assets.write 'app').to eq name
      end
    end

    context "when gzip true" do

      it "still returns the non-gzipped asset name" do
        allow(asset).to receive(:write_to)
        expect(assets.write 'app', gzip: true).to eq name
      end

      it "it gzips the assets as well" do
        expect(asset).to receive(:write_to).at_most(:once).with("#{name}.gz", compress: true)
        expect(asset).to receive(:write_to).at_most(:once).with(name)
        assets.write 'app', gzip: true
      end
    end

    context "when hash true" do

      it "hashes the file name" do
        allow(asset).to receive(:digest).and_return('cb5a921a4e7663347223c41cd2fa9e11')
        expect(asset).to receive(:write_to).with('app-cb5a921a4e7663347223c41cd2fa9e11.js')
        assets.write 'app', hash: true
      end
    end
  end

  describe ".find_tags and #find_tags" do

    let(:grep) { [ 'grep', '-l', '-I', '-r', '-E' ] }
    let(:matches) { double IO }

    describe ".find_tags" do

      let(:regex) { '\[%(\s+(\w|\s)+?)%\]' }

      it "fails if path is empty" do
        expect { assets.find_tags '' }.to raise_error ArgumentError
      end

      it "greps in the path" do
        expect(Open3).to receive(:popen2).with(*grep, regex, '/the/path')
        Kit::Bit::Assets.find_tags '/the/path'
      end

      it "greps for only the asset tag for the given type" do
        expect(Open3).to receive(:popen2).with(*grep, '\[%(\s+javascript\s+(\w|\s)+?)%\]', '/the/path')
        Kit::Bit::Assets.find_tags '/the/path', :javascript
      end

      it "merges options" do
        expect(Open3).to receive(:popen2).with(*grep, '\(%(\s+javascript\s+(\w|\s)+?)%\]', '/the/path')
        Kit::Bit::Assets.find_tags '/the/path', :javascript, src_pre: '(%'
      end

      it "returns an array of results" do
        allow(Open3).to receive(:popen2).with(*grep, regex, '/the/path').and_yield(nil, matches)
        allow(matches).to receive(:gets).and_return("first/match_1\nsecond/match_2")
        expect(Kit::Bit::Assets.find_tags '/the/path').to eq [ 'first/match_1', 'second/match_2' ]
      end
    end

    describe "#find_tags" do

      it "uses the type as the type" do
        assets.type = :javascript
        expect(Kit::Bit::Assets).to receive(:find_tags).with(anything, :javascript, anything)
        assets.find_tags path: '/the/path'
      end

      it "uses the options as the options" do
        expect(Kit::Bit::Assets).to receive(:find_tags).with(anything, anything, assets.options)
        assets.find_tags path: '/the/path'
      end

      it "uses the directory as the path" do
        assets.directory = '/the/directory'
        expect(Kit::Bit::Assets).to receive(:find_tags).with('/the/directory', anything, anything)
        assets.find_tags
      end

      it "can use an alternative path" do
        assets.directory = '/the/directory'
        expect(Kit::Bit::Assets).to receive(:find_tags).with('/the/path', anything, anything)
        assets.find_tags path: '/the/path'
      end
    end
  end

  describe "#update_source and #update_source!" do

    let(:asset) { double Sprockets::Asset }

    let(:source) do
      <<-EOF
        <head>
          <script src="[% javascript app %]"></script>
          <script src="[% javascript vendor/modernizr %]"></script>
          <script>
            [% javascript inline vendor/tracking %]
          </script>
        </head>
      EOF
    end

    let(:result) do
      <<-EOF
        <head>
          <script src="app-1234.js"></script>
          <script src="vendor/modernizr-5678.js"></script>
          <script>
            alert('track');
          </script>
        </head>
      EOF
    end

    before :each do
      assets.type = :javascripts
      allow(assets).to receive(:write).with('app').and_return('app-1234.js')
      allow(assets).to receive(:write).with('vendor/modernizr').and_return('vendor/modernizr-5678.js')
      allow(assets.assets).to receive(:[]).with('vendor/tracking').and_return(asset)
      allow(asset).to receive(:to_s).and_return(%q{alert('track');})
    end

    describe "#update_source!" do

      it "replaces asset tags in sources" do
        assets.update_source! source
        expect(source).to eq result
      end
    end

    describe "#update_source" do

      it "replaces asset tags in sources" do
        expect(assets.update_source source).to eq result
      end

      it "does not change input string" do
        assets.update_source source
        expect(source).to eq source
      end
    end
  end
end
