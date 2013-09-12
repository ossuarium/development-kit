require 'spec_helper'

describe Kit::Bit do

  describe "#name" do
    it "returns the bit name" do
      bit = create :bit, name: 'bit name'
      expect(bit.name).to eq 'bit name'
    end
  end
end
