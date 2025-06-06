require_relative '../../spec_helper'

describe "Set#flatten_merge" do
  ruby_version_is ""..."3.5" do
    it "is protected" do
      Set.should have_protected_instance_method("flatten_merge")
    end

    it "flattens the passed Set and merges it into self" do
      set1 = Set[1, 2]
      set2 = Set[3, 4, Set[5, 6]]

      set1.send(:flatten_merge, set2).should == Set[1, 2, 3, 4, 5, 6]
    end

    it "raises an ArgumentError when trying to flatten a recursive Set" do
      set1 = Set[1, 2, 3]
      set2 = Set[5, 6, 7]
      set2 << set2

      -> { set1.send(:flatten_merge, set2) }.should raise_error(ArgumentError)
    end
  end
end
