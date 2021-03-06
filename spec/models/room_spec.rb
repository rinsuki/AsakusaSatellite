# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

describe Room do
  shared_examples_for '妥当でない部屋'  do
    its(:save) { should be_falsey }
    its(:validate) { should be_falsey }
  end

  context "タイトルが空" do
    subject{ Room.new(:title => '') }
    it_should_behave_like '妥当でない部屋'
  end
  context "タイトルがnil" do
    subject{ Room.new(:title => nil) }
    it_should_behave_like '妥当でない部屋'
  end
  context "初期状態" do
    subject { Room.new }
    it_should_behave_like '妥当でない部屋'
  end

  describe "all_live" do
    before(:each) do
      Room.delete_all
    end

    context "rooms が空" do
      subject { Room.all_live }
      it { should have(0).records }
    end

    context "rooms が2個" do
      before do
        Room.new(:title => 'room1', :user => nil, :updated_at => Time.now).save
        Room.new(:title => 'room2', :user => nil, :updated_at => Time.now).save
      end

      subject { Room.all_live }
      it { should have(2).records }
    end

    context "duplicated nickname rooms" do
      before do
        Room.delete_all(:nickname => 'nickname')
        Room.new(:title => 'room1', :nickname => 'nickname').save
        @room = Room.new(:title => 'room2', :nickname => 'nickname')
        @room.save
      end
      subject { @room.errors }
      it { should have(1).items }
    end

    context "rooms が2個かつ1個削除されている" do
      before do
        Room.new(:title => 'room1', :user => nil, :updated_at => Time.now).save!
        room = Room.new(:title => 'room2', :user => nil, :updated_at => Time.now)
        room.deleted = true
        room.save!
      end

      subject { Room.all_live }
      it { should have(1).records }
    end
  end

  context "to_param" do
    context "with nickname" do
      before do
        Room.delete_all(:nickname => 'nickname')
        @room = Room.new(:title => 'room', :nickname => 'nickname')
        @room.save
      end
      subject { @room }
      its(:to_param) { should == 'nickname' }
    end
    context "without nickname" do
      before do
        Room.delete_all(:nickname => 'nickname')
        @room = Room.new(:title => 'room', :nickname => '')
        @room.save
      end
      subject { @room }
      its(:to_param) { should == @room.id.to_s }
    end
  end

  before {
    @user = User.new
    @room = Room.new(:title => 'room1', :user => @user, :nickname => 'nickname', :updated_at => Time.now)
  }
  describe "to_json" do
    subject { @room.to_json }
    its([:name]) { should == "room1" }
    its([:user])  { should == @user.to_json }
    its([:nickname])  { should == "nickname" }
    its([:updated_at]) { should == @room.updated_at.to_s }
    its([:members]) { should == [] }
  end

  describe "yaml field" do
    before  { @room.yaml = { 'foo' => 'baz' } }
    subject { @room.yaml }
    its(['foo']) { should == 'baz' }
    it{ should have(1).items }
  end

  describe "messages" do
    before do
      @messages = (0..10).map do|i|
        Message.create!(:body => "body of message #{i}", :room => @room)
      end
    end
    context "messages" do
      describe "without order" do
        subject { @room.messages(5) }
        it { should have(5).items }
        it { should == @messages[6..10] }
      end
      describe "with order :asc" do
        subject { @room.messages(5, :asc) }
        it { should have(5).items }
        it { should == @messages[0..4] }
      end
      describe "with order :desc" do
        subject { @room.messages(5, :desc) }
        it { should have(5).items }
        it { should == @messages[6..10].reverse }
      end
    end

    context "messages_between" do
      before {
        @message3  = {:id => @messages[3].id, :include_boundary => true}
        @message5  = {:id => @messages[5].id, :include_boundary => true}
        @message3_ = {:id => @messages[3].id, :include_boundary => false}
        @message5_ = {:id => @messages[5].id, :include_boundary => false}
      }
      context "without order paramemter" do
        describe "messages_between" do
          describe "3 <= n <= 5" do
            subject { @room.messages_between(@message3, @message5, 2) }
            it { should == @messages[3..4] }
          end
          describe "3 < n <= 5" do
            subject { @room.messages_between(@message3_, @message5, 2) }
            it { should == @messages[4..5] }
          end
          describe "3 <= n < 5" do
            subject { @room.messages_between(@message3, @message5_, 2) }
            it { should == @messages[3..4] }
          end
          describe "3 < n < 5" do
            subject { @room.messages_between(@message3_, @message5_, 2) }
            it { should == [@messages[4]] }
          end
        end

        describe "messages_between without both since_id and until_id" do
          subject { @room.messages_between(nil, nil, 2) }
          it { should == @messages[0..1] }
        end

        describe "messages_between with only since_id" do
          describe "5 <= n" do
            subject { @room.messages_between(@message5, nil, 2) }
            it { should == @messages[5..6] }
          end
          describe "5 < n" do
            subject { @room.messages_between(@message5_, nil, 2) }
            it { should == @messages[6..7] }
          end
        end

        describe "messages_between with only until_id" do
          describe "n <= 5" do
            subject { @room.messages_between(nil, @message5, 2) }
            it { should == @messages[4..5].reverse }
          end
          describe "n < 5" do
            subject { @room.messages_between(nil, @message5_, 2) }
            it { should == @messages[3..4].reverse }
          end
        end
      end
      context "with :asc" do
        describe "messages_between" do
          describe "3 <= n <= 5" do
            subject { @room.messages_between(@message3, @message5, 2, :asc) }
            it { should == @messages[3..4] }
          end
          describe "3 < n <= 5" do
            subject { @room.messages_between(@message3_, @message5, 2, :asc) }
            it { should == @messages[4..5] }
          end
          describe "3 <= n < 5" do
            subject { @room.messages_between(@message3, @message5_, 2, :asc) }
            it { should == @messages[3..4] }
          end
          describe "3 < n < 5" do
            subject { @room.messages_between(@message3_, @message5_, 2, :asc) }
            it { should == [@messages[4]] }
          end
        end

        describe "messages_between without both since_id and until_id" do
          subject { @room.messages_between(nil, nil, 2, :asc) }
          it { should == @messages[0..1] }
        end

        describe "messages_between with only since_id" do
          describe "5 <= n" do
            subject { @room.messages_between(@message5, nil, 2, :asc) }
            it { should == @messages[5..6] }
          end
          describe "5 < n" do
            subject { @room.messages_between(@message5_, nil, 2, :asc) }
            it { should == @messages[6..7] }
          end
        end

        describe "messages_between with only until_id" do
          describe "n <= 5" do
            subject { @room.messages_between(nil, @message5, 2, :asc) }
            it { should == @messages[4..5] }
          end
          describe "n < 5" do
            subject { @room.messages_between(nil, @message5_, 2, :asc) }
            it { should == @messages[3..4] }
          end
        end
      end
      context "with :desc" do
        describe "messages_between" do
          describe "3 <= n <= 5" do
            subject { @room.messages_between(@message3, @message5, 2, :desc) }
            it { should == @messages[4..5].reverse }
          end
          describe "3 < n <= 5" do
            subject { @room.messages_between(@message3_, @message5, 2, :desc) }
            it { should == @messages[4..5].reverse }
          end
          describe "3 <= n < 5" do
            subject { @room.messages_between(@message3, @message5_, 2, :desc) }
            it { should == @messages[3..4].reverse }
          end
          describe "3 < n < 5" do
            subject { @room.messages_between(@message3_, @message5_, 2, :desc) }
            it { should == [@messages[4]] }
          end
        end

        describe "messages_between without both since_id and until_id" do
          subject { @room.messages_between(nil, nil, 2, :desc) }
          it { should == @messages[9..10].reverse }
        end

        describe "messages_between with only since_id" do
          describe "5 <= n" do
            subject { @room.messages_between(@message5, nil, 2, :desc) }
            it { should == @messages[9..10].reverse }
          end
          describe "5 < n" do
            subject { @room.messages_between(@message5_, nil, 2, :desc) }
            it { should == @messages[9..10].reverse }
          end
        end

        describe "messages_between with only until_id" do
          describe "n <= 5" do
            subject { @room.messages_between(nil, @message5, 2, :desc) }
            it { should == @messages[4..5].reverse }
          end
          describe "n < 5" do
            subject { @room.messages_between(nil, @message5_, 2, :desc) }
            it { should == @messages[3..4].reverse }
          end
        end
      end
    end
  end

  describe "owner and members" do
    before do
      @user = User.create
      @member = User.create
      @room = Room.create(:title => 'room private', :user => @user, :is_public => false)
      @room.members << @member
      @public_room = Room.create(:title => 'room public', :user => @user, :is_public => true)
    end

    context "user" do
      subject { @room.user }
      it { should == @user }
    end

    context "members" do
      subject { @room.members.to_set }
      it { should == [@member].to_set }
    end

    context "owner_and_members" do
      context "exist members" do
        subject { @room.owner_and_members.to_set }
        it { should == [@user, @member].to_set }
      end

      context "no members" do
        before do
          @room = Room.create(:title => 'room private', :user => @user, :is_public => false)
        end

        subject { @room.owner_and_members.to_set }
        it { should == [@user].to_set }
      end

      context "public room" do
        subject { @public_room.owner_and_members }
        it { should == [] }
      end
    end

    context "to_json" do
      subject { @room.to_json }
      its([:members]) { should == [@member.to_json] }
    end
  end

  describe "accessible?" do
    context "publicな部屋" do
      before {
        @room = Room.create(:title => 'room public', :user => @user, :is_public => true)
      }

      subject { @room.accessible?(@user) }
      it { should be_truthy }
    end

    context "privateな部屋" do
      before do
        @member = User.create
        @other = User.create
        @room = Room.create(:title => 'room public', :user => @user, :is_public => false)
        @room.members << @member
      end

      context "owner" do
        subject { @room.accessible? @user }
        it { should be_truthy }
      end

      context "member" do
        subject { @room.accessible? @member }
        it { should be_truthy }
      end

      context "その他" do
        subject { @room.accessible? @other }
        it { should be_falsey }
      end
    end
  end
end
