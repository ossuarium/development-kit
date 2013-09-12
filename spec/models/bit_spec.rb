require 'spec_helper'

# Uncomment below if you have added to the basic bit model.
# require_relative '../../models/bit'

describe Kit::Bit do

  describe "#name" do
    it "returns the bit name" do
      bit = create :bit, name: 'bit name'
      expect(bit.name).to eq 'bit name'
    end
  end
end
