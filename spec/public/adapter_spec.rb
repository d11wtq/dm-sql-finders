require "spec_helper"

describe DataMapper::Adapters::DataObjectsAdapter do
  context "querying by SQL" do
    before(:each) do
      @bob  = User.create(:username => "Bob",  :role => "Manager")
      @fred = User.create(:username => "Fred", :role => "Tea Boy")
    end

    context "with a basic SELECT statement" do
      before(:each) do
        @users = User.by_sql { |u| ["SELECT #{u.*} FROM #{u} WHERE #{u.role} = ?", "Manager"] }
        @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
      end

      it "executes the original query" do
        @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" WHERE "users"."role" = ? ORDER BY "users"."id"}
        @bind_values.should == ["Manager"]
      end

      it "finds the matching resources" do
        @users.should include(@bob)
      end

      it "does not find incorrect resources" do
        @users.should_not include(@fred)
      end

      describe "chaining" do
        describe "to #all" do
          before(:each) do
            @jim   = User.create(:username => "Jim", :role => "Manager")
            @users = @users.all(:username => "Jim")
            @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
          end

          it "merges the conditions with the original SQL" do
            @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" WHERE "users"."role" = ? AND "users"."username" = ? ORDER BY "users"."id"}
            @bind_values.should == ["Manager", "Jim"]
          end

          it "finds the matching resources" do
            @users.should include(@jim)
          end

          it "does not find incorrect resources" do
            @users.should_not include(@bob)
          end
        end
      end
    end

    context "with an ORDER BY clause" do
      before(:each) do
        @users = User.by_sql { |u| "SELECT #{u.*} FROM #{u} ORDER BY #{u.username} DESC" }
        @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
      end

      it "uses the order from the SQL" do
        @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."username" DESC}
      end
    end

    context "with :order specified in the query" do
      before(:each) do
        @users = User.by_sql(:order => [:role.desc]) { |u| "SELECT #{u.*} FROM #{u}" }
        @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
      end

      it "uses the order from the options" do
        @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."role" DESC}
      end
    end

    context "with an INNER JOIN" do
      before(:each) do
        @bobs_post  = @bob.posts.create(:title => "Bob can write posts")
        @freds_post = @fred.posts.create(:title => "Fred likes to write too")

        @posts = Post.by_sql(User) { |p, u| ["SELECT #{p.*} FROM #{p} INNER JOIN #{u} ON #{p.user_id} = #{u.id} WHERE #{u.id} = ?", @bob.id] }
        @sql, @bind_values = Post.repository.adapter.send(:select_statement, @posts.query)
      end

      it "executes the original query" do
        @sql.should == %q{SELECT "posts"."id", "posts"."title", "posts"."user_id" FROM "posts" INNER JOIN "users" ON "posts"."user_id" = "users"."id" WHERE "users"."id" = ? ORDER BY "posts"."id"}
        @bind_values.should == [@bob.id]
      end

      it "finds the matching resources" do
        @posts.should include(@bobs_post)
      end

      it "does not find incorrect resources" do
        @posts.should_not include(@freds_post)
      end
    end
  end
end
