require "spec_helper"

describe DataMapper::Adapters::DataObjectsAdapter do
  context "querying by SQL" do
    context "with a basic SELECT statement" do
      before(:each) do
        @bob   = User.create(:username => "Bob")
        @fred  = User.create(:username => "Fred")
        @users = User.by_sql { |u| ["SELECT #{u.*} FROM #{u} WHERE #{u.id} = ?", @bob.id] }
        @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
      end

      it "executes the original query" do
        @sql.should == %q{SELECT "users"."id", "users"."username" FROM "users" WHERE "users"."id" = ?}
        @bind_values.should == [@bob.id]
      end

      it "finds the matching resources" do
        @users.should include(@bob)
      end

      it "does not find incorrect resources" do
        @users.should_not include(@fred)
      end
    end
  end
end
