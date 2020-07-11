class Api::V1::DecksController < Api::V1::BaseController
  acts_as_token_authentication_handler_for User, except: %i[global]
  before_action :authenticate_user!, except: %i[global]
  before_action :set_deck, only: %i[update]

  def global
    # curl -s http://localhost:3000/api/v1/decks/global
    # @decks_global = policy_scope(Deck).globally_available(true)

    value_hash = search_values(params)
    value_hash[:user] = nil
    search_hash = { global: true, mydecks: false, myarchived: false, shared_read: false, shared_update: false }
    @decks = policy_scope(deck_search(value_hash, search_hash)).order(updated_at: :desc)
    deck_strings = string_hash(@decks, nil, value_hash[:language])

    render json: { data: { partials: generate_partials(deck_strings), formats: [:json], layout: false } }
  end

  def mydecks
    if user_signed_in?
      @user = current_user
      # curl -i -X GET \
      # -H 'X-User-Email: pups0@example.com' \
      # -H 'X-User-Token: SzRrzWThqfnd2aK7t67C' \
      # http://localhost:3000/api/v1/decks/mydecks

      value_hash = search_values(params)
      value_hash[:user] = @user
      search_hash = { global: false, mydecks: true, myarchived: false, shared_read: false, shared_update: false }
      @decks = policy_scope(deck_search(value_hash, search_hash)).order(updated_at: :desc)
      decks_owned_strings = string_hash(@decks, @user, value_hash[:language])

      render json: { data: { partials: generate_partials(decks_owned_strings), formats: [:json], layout: false } }
    end
  end

  def myarchived
    if user_signed_in?
      @user = current_user

      value_hash = search_values(params)
      value_hash[:user] = @user
      search_hash = { global: false, mydecks: false, myarchived: true, shared_read: false, shared_update: false }
      @decks = policy_scope(deck_search(value_hash, search_hash)).order(updated_at: :desc)
      archived_deck_strings = string_hash(@decks, @user, value_hash[:language])

      render json: { data: { partials: generate_partials(archived_deck_strings), formats: [:json], layout: false } }
    end
  end

  def shared_read
    if user_signed_in?
      @user = current_user

      value_hash = search_values(params)
      value_hash[:user] = @user
      search_hash = { global: false, mydecks: false, myarchived: false, shared_read: true, shared_update: false }
      @decks = policy_scope(deck_search(value_hash, search_hash)).order(updated_at: :desc)
      shared_read_strings = string_hash(@decks, @user, value_hash[:language])

      render json: { data: { partials: generate_partials(shared_read_strings), formats: [:json], layout: false } }
    end
  end

  def shared_update
    if user_signed_in?
      @user = current_user

      value_hash = search_values(params)
      value_hash[:user] = @user
      search_hash = { global: false, mydecks: false, myarchived: false, shared_read: false, shared_update: true }
      @decks = policy_scope(deck_search(value_hash, search_hash)).order(updated_at: :desc)
      shared_update_strings = string_hash(@decks, @user, value_hash[:language])

      render json: { data: { partials: generate_partials(shared_update_strings), formats: [:json], layout: false } }
    end
  end

  def update
    authorize(@deck)
    if @deck.update!(deck_params)
      render json: @deck
    else
      render_error
    end
  end

  private

  def deck_params
    params.require(:deck).permit(
      :default_language,
      :global_deck_read,
      :archived,
      collections_attributes: [collection_strings_attributes:
        [:language, :title, :description]],
      deck_strings_attributes: [:language, :title, :description]
    )
  end

  def set_deck
    @deck = Deck.find(params[:id])
  end

  def render_error
    render json: { errors: @membership.errors.full_messages },
      status: :unprocessable_entity
  end

  def string_hash(decks, user, language)
    string_hash = {
      objects: decks,
      string_type: 'deck_strings',
      id_type: :deck_id,
      permission_type: nil,
      deck: nil,
      language: language
    }
    string_hash[:user] = user unless user.nil?
    string_hash
  end

  def deck_search(value_hash, search_hash)
    DeckSearchService.new(value_hash).call(search_hash)
  end

  def generate_partials(deck_strings)
    strings = PopulateStrings.new(deck_strings).call
    array = []
    strings.each do |string|
      array << render_to_string(
        partial: 'deck_panel',
        locals: { deck_string: string }
      )
    end
    array
  end

  def search_values(params)
    if params.key?('category')
      language = params['category']['language']
      category_ids = params['category']['name']
      tags = params['category']['tag']
    else # account for going straight to /shared_decks
      language = 'en'
      category = Category.find_by(name: 'All Categories')
      category_ids = [category.id]
    end
    { language: language, categories: category_ids, tags: tags }
  end
end
