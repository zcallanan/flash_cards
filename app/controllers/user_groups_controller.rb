class UserGroupsController < ApplicationController
  before_action :set_user_group, only: %i[show]

  def index
    @user = current_user
    @user_groups_owned = policy_scope(UserGroup).joins(:memberships).where(user: @user).distinct
    @user_groups_read = policy_scope(UserGroup).joins(users: [:memberships, :decks]).where({ memberships: { user_id: @user.id, read_access: true, update_access: false } }, decks: { archived: false }).where.not(user: @user).distinct
    @user_groups_update = policy_scope(UserGroup).joins(users: [:memberships, :decks]).where({ memberships: { user_id: @user.id, read_access: true, update_access: true } }, decks: { archived: false }).where.not(user: @user).distinct

    @user_group = UserGroup.new
    # prepare simple_field usage
    @user_group.decks.build
    @user_group.collections.build
    @user_group.question_sets.build
    # generate option arrays for form fields
    @deck_select = select_options(@user, 'decks', 'deck_strings')
    @collection_select = select_options(@user, 'collections', 'collection_strings', 'deck')
    @question_set_select = select_options(@user, 'question_sets', 'question_set_strings', 'deck')
    @tag_set_select = select_options(@user, 'tag_sets', 'tag_set_strings', 'deck')
  end

  def show
    # build a list of all members, owner first, in view should not be able to edit that row
    memberships = Membership.all.where(user_group: @user_group)
    owner = Membership.find(@user_group.user.id)
    @members = []
    @members << owner
    memberships.each { |member| @members << member if member.user_id != @user_group.user.id }
    @membership = Membership.new
  end

  def create
    @user_group = UserGroup.new(user_group_params)
    @user_group.user = current_user

    if @user_group.save
      Membership.create!(
        user: current_user,
        user_group: @user_group,
        user_label: 'Group Owner',
        status: 'Managing Owner',
        read_access: true,
        update_access: true
      )
      params['user_group']['user_group_deck']['deck_id'].each { |id| UserGroupDeck.create!(user_group: @user_group, deck: Deck.find(id)) }
      params['user_group']['user_group_collection']['collection_id'].each { |id| UserGroupCollection.create!(user_group: @user_group, collection: Collection.find(id)) }
      params['user_group']['user_group_question_set']['question_set_id'].each { |id| UserGroupQuestionSet.create!(user_group: @user_group, question_set: QuestionSet.find(id)) }
      params['user_group']['user_group_tag_set']['tag_set_id'].each { |id| UserGroupTagSet.create!(user_group: @user_group, tag_set: TagSet.find(id)) }
      redirect_to user_group_path(@user_group)
    # else
    #   render :index
    end

    authorize @user_group
  end

  private

  def set_user_group
    @user_group = UserGroup.find(params[:id])
    authorize @user_group
  end

  def user_group_params
    params.require(:user_group).permit(:name, deck_ids: [], collection_ids: [], question_set_ids: [])
  end

  def select_options(user, objects, method, deck_string = nil)
    # objects ~ decks, method ~ deck_strings, id_string ~ deck_id
    object_list = []
    user.send(objects).each do |object|
      object.send(method).each do |string|
        next if object_list.flatten.include?(object.id)

        if string.language == user.language && user.id == string.user_id # if the object has a string with the user's preferred language
          object_list << [string.title, object.id]
        elsif deck_string.nil? && user.id == string.user_id # if the object is a deck, choose the deck_string with the deck's default language
          object_list << [string.title, object.id] if string.language == object.default_language
        elsif !deck_string.nil? && user.id == string.user_id # if the object is  not a deck, choose the string with the deck's default language
          object_list << [string.title, object.id] if string.language == object.send(deck_string).default_language
        end
      end
    end
    object_list
  end
end
