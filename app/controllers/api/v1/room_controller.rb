# -*- encoding: utf-8 -*-
module Api
  module V1
    class RoomController < ApplicationController
      include ChatHelper
      include ApiHelper

      before_filter :check_spell

      respond_to :json
      def create
        unless logged?
          render_login_error
          return
        end
        room = Room.new(:title => params[:name], :user => current_user, :updated_at => Time.now)
        if room.save
          render :json => {:status => 'ok', :room_id => room._id}
        else
          render :json => {:status => 'error', :error => "room creation failure"}
        end
      end

      def update
        case Room.configure(params[:id], current_user, :title => params[:name])
        when Room                  then render :json => {:status => 'ok'}
        when :login_error          then render_login_error
        when :error_room_not_found then render_room_not_found(params[:id])
        when :error_on_save        then render_error_on_save
        end
      end

      def destroy
        case Room.delete(params[:id], current_user)
        when Room                  then render :json => {:status => 'ok'}
        when :login_error          then render_login_error
        when :error_room_not_found then render_room_not_found(params[:id])
        when :error_on_save        then render_error_on_save
        end
      end

      def list
        render :json => Room.all_live(current_user).map {|r| r.to_json }
      end

      def add_member
        unless logged?
          render_login_error
          return
        end
        Room.with_room(params[:id], current_user) do |room|
          user = User.find(params[:user_id])
          if room.nil?
            render :json => {:status => 'error', :error => "room not found"}
            return
          elsif user.nil?
            render :json => {:status => 'error', :error => "user not found"}
            return
          end

          room.members ||= []
          member = room.members.where(:_id => user.id).first
          unless member.nil?
            render :json => {:status => 'error', :error => "user already exists"}
            return
          end

          room.members << user
          if room.save
            render :json => {:status => 'ok'}
          else
            render :json => {:status => 'error', :error => "add user"}
          end
        end
      end
    end
  end
end
