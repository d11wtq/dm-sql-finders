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

    describe "ordering" do
      context "with an ORDER BY clause" do
        before(:each) do
          @users = User.by_sql { |u| "SELECT #{u.*} FROM #{u} ORDER BY #{u.username} DESC" }
          @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
        end

        it "uses the order from the SQL" do
          @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."username" DESC}
        end

        it "loads the resources in the correct order" do
          @users.to_a.first.should == @fred
          @users.to_a.last.should == @bob
        end
      end

      context "with :order specified on the query" do
        before(:each) do
          @users = User.by_sql(:order => [:role.asc]) { |u| "SELECT #{u.*} FROM #{u}" }
          @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
        end

        it "uses the order from the options" do
          @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."role"}
        end

        it "loads the resources in the correct order" do
          @users.to_a.first.should == @bob
          @users.to_a.last.should == @fred
        end
      end

      context "with both :order and an ORDER BY clause" do
        before(:each) do
          @users = User.by_sql(:order => [:role.desc]) { |u| "SELECT #{u.*} FROM #{u} ORDER BY #{u.username} ASC" }
          @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
        end

        it "gives the :order option precendence" do
          @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."role" DESC}
        end
      end

      describe "chaining" do
        describe "overriding a previous :order option" do
          before(:each) do
            @users = User.by_sql(:order => [:role.desc]) { |u| "SELECT #{u.*} FROM #{u}" }.all(:order => [:id.asc])
            @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
          end

          specify "the last :order specified is used" do
            @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."id"}
          end
        end

        describe "overriding the order specified in the SQL" do
          before(:each) do
            @users = User.by_sql { |u| "SELECT #{u.*} FROM #{u} ORDER BY #{u.role} DESC" }.all(:order => [:id.asc])
            @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
          end

          specify "the last :order specified is used" do
            @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."id"}
          end
        end
      end
    end

    describe "limits" do
      context "with a limit specified by the SQL" do
        before(:each) do
          @users = User.by_sql { |u| "SELECT #{u.*} FROM #{u} LIMIT 1" }
          @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
        end

        it "uses the limit from the SQL" do
          @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."id" LIMIT ?}
          @bind_values.should == [1]
        end

        it "finds the matching resources" do
          @users.to_a.should have(1).items
          @users.to_a.first.should == @bob
        end
      end

      context "with a :limit option to #by_sql" do
        before(:each) do
          @users = User.by_sql(:limit => 1) { |u| "SELECT #{u.*} FROM #{u}" }
          @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
        end

        it "uses the :limit option" do
          @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."id" LIMIT ?}
          @bind_values.should == [1]
        end

        it "finds the matching resources" do
          @users.to_a.should have(1).items
          @users.to_a.first.should == @bob
        end
      end

      context "with both a :limit option and a LIMIT in the SQL" do
        before(:each) do
          @users = User.by_sql(:limit => 1) { |u| "SELECT #{u.*} FROM #{u} LIMIT 2" }
          @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
        end

        it "the :limit option takes precedence" do
          @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."id" LIMIT ?}
          @bind_values.should == [1]
        end
      end

      context "with an OFFSET in the SQL" do
        before(:each) do
          @users = User.by_sql { |u| "SELECT #{u.*} FROM #{u} LIMIT 1 OFFSET 1" }
          @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
        end

        it "uses the offset from the SQL" do
          @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."id" LIMIT ? OFFSET ?}
          @bind_values.should == [1, 1]
        end

        it "finds the matching resources" do
          @users.to_a.should have(1).items
          @users.to_a.first.should == @fred
        end
      end

      context "with an argument to LIMIT in the SQL" do
        before(:each) do
          @users = User.by_sql { |u| "SELECT #{u.*} FROM #{u} LIMIT 1, 2" }
          @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
        end

        it "interprets the offset in the SQL" do
          @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."id" LIMIT ? OFFSET ?}
          @bind_values.should == [2, 1]
        end
      end

      context "with an :offset option to #by_sql" do
        before(:each) do
          @users = User.by_sql(:offset => 1) { |u| "SELECT #{u.*} FROM #{u} LIMIT 1" }
          @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
        end

        it "uses the offset from the options hash" do
          @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."id" LIMIT ? OFFSET ?}
          @bind_values.should == [1, 1]
        end

        it "finds the matching resources" do
          @users.to_a.should have(1).items
          @users.to_a.first.should == @fred
        end
      end

      context "with both an OFFSET in the SQL and an :offset option" do
        before(:each) do
          @users = User.by_sql(:offset => 1) { |u| "SELECT #{u.*} FROM #{u} LIMIT 1 OFFSET 0" }
          @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
        end

        it "the :offset in the options takes precendence" do
          @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."id" LIMIT ? OFFSET ?}
          @bind_values.should == [1, 1]
        end
      end

      describe "chaining" do
        describe "to override a previous :limit option" do
          before(:each) do
            @users = User.by_sql(:limit => 2) { |u| "SELECT #{u.*} FROM #{u}" }.all(:limit => 1)
            @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
          end

          it "the last :limit option takes precedence" do
            @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."id" LIMIT ?}
            @bind_values.should == [1]
          end
        end

        describe "to override a limit applied in SQL" do
          before(:each) do
            @users = User.by_sql { |u| "SELECT #{u.*} FROM #{u} LIMIT 1" }.all(:limit => 2)
            @sql, @bind_values = User.repository.adapter.send(:select_statement, @users.query)
          end

          it "the last :limit option takes precedence" do
            @sql.should == %q{SELECT "users"."id", "users"."username", "users"."role" FROM "users" ORDER BY "users"."id" LIMIT ?}
            @bind_values.should == [2]
          end
        end
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

    describe "with virtual attributes" do
      before(:each) do
        @bob.posts.create(:title => "Test")
        @users = User.by_sql(Post) { |u, p| "SELECT #{u.*}, COUNT(#{p.id}) AS post_count FROM #{u} INNER JOIN #{p} ON #{p.user_id} = #{u.id}" }
      end

      it "loads the virtual attributes" do
        @users.to_a.first.post_count.should == 1
      end
    end
  end
end
