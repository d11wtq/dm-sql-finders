require "spec_helper"

describe DataMapper::Adapters::DataObjectsAdapter do
  context "querying by SQL" do
    context "with a basic SELECT statement" do
      before(:each) do
        @users = User.by_sql { |u| "SELECT #{u.*} FROM #{u}" }
        @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
      end

      it "executes the original query" do
        @sql.should == %q{SELECT "users"."id", "users"."username" FROM "users"}
      end
    end
  end
end
