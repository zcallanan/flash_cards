class Api::V1::DecksController < Api::V1::BaseController
  acts_as_token_authentication_handler_for User, except: %i[global rated_decks]
  before_action :authenticate_user!, except: %i[global rated_decks]
  before_action :set_deck, only: %i[update]

  def global
    # curl -s http://localhost:3000/api/v1/decks/global

    value_hash = search_values(params)
    value_hash[:user] = nil
    search_hash = { global: true }
    decks = policy_scope(deck_search(value_hash, search_hash)).order(updated_at: :desc)
    deck_strings = string_hash(decks, nil, value_hash[:language], 'deck_strings', :deck_id, nil)

    render json: { data: { partials: generate_partials(deck_strings, 'deck_panel'), formats: [:json], layout: false } }
  end

  def mydecks
    if user_signed_in?
      user = current_user
      # curl -i -X GET \
      # -H 'X-User-Email: pups0@example.com' \
      # -H 'X-User-Token: vxpCgEw8q9Tp2_UTLvvs' \
      # http://localhost:3000/api/v1/decks/mydecks

      value_hash = search_values(params)
      value_hash[:user] = user
      search_hash = { mydecks: true }
      decks = policy_scope(deck_search(value_hash, search_hash)).order(updated_at: :desc)
      decks_owned_strings = string_hash(decks, user, value_hash[:language], 'deck_strings', :deck_id, nil)

      render json: { data: { partials: generate_partials(decks_owned_strings, 'deck_panel'), formats: [:json], layout: false } }
    end
  end

  def myarchived
    # curl -i -X GET \
    # -H 'X-User-Email: pups0@example.com' \
    # -H 'X-User-Token: vxpCgEw8q9Tp2_UTLvvs' \
    # http://localhost:3000/api/v1/decks/myarchived?category%5Btitle%5D=one&category%5Bname%5D%5B%5D=1&category%5Blanguage%5D=en
    if user_signed_in?
      user = current_user

      value_hash = search_values(params)
      value_hash[:user] = user
      search_hash = { myarchived: true }
      decks = policy_scope(deck_search(value_hash, search_hash)).order(updated_at: :desc)
      archived_deck_strings = string_hash(decks, user, value_hash[:language], 'deck_strings', :deck_id, nil)

      render json: { data: { partials: generate_partials(archived_deck_strings, 'deck_panel'), formats: [:json], layout: false } }
    end
  end

  def shared_read
    if user_signed_in?
      user = current_user

      value_hash = search_values(params)
      value_hash[:user] = user
      search_hash = { shared_read: true }
      decks = policy_scope(deck_search(value_hash, search_hash)).order(updated_at: :desc)
      shared_read_strings = string_hash(decks, user, value_hash[:language], 'deck_strings', :deck_id, nil)

      render json: { data: { partials: generate_partials(shared_read_strings, 'deck_panel'), formats: [:json], layout: false } }
    end
  end

  def shared_update
    if user_signed_in?
      user = current_user

      value_hash = search_values(params)
      value_hash[:user] = user
      search_hash = { shared_update: true }
      decks = policy_scope(deck_search(value_hash, search_hash)).order(updated_at: :desc)
      shared_update_strings = string_hash(decks, user, value_hash[:language], 'deck_strings', :deck_id, nil)

      render json: { data: { partials: generate_partials(shared_update_strings, 'deck_panel'), formats: [:json], layout: false } }
    end
  end

  def recent_decks
    # get 1, 2, or 3 of the most recently viewed decks of the respective tab
    # curl -i -X GET \
    # -H 'X-User-Email: pups0@example.com' \
    # -H 'X-User-Token: vxpCgEw8q9Tp2_UTLvvs' \
    # http://localhost:3000/api/v1/decks/recent_decks?dest=global
    if user_signed_in?
      user = current_user

      # respective tab
      dest = params[:dest]

      # determine what type of search
      if dest == 'global'
        search_hash = { global: true }
      elsif dest == 'mydecks'
        search_hash = { allmydecks: true } # this covers all mydecks and myarchiveddecks
      elsif dest == 'shared_read'
        search_hash = { allshared: true } # this covers all shared read and update decks
      end

      value_hash = search_values(params)
      value_hash[:user] = user
      value_hash[:recent_decks] = true

      # call search service
      decks = policy_scope(deck_search(value_hash, search_hash)).order(updated_at: :desc)

      # return different partials according to number of decks recently viewed
      size = decks.size
      if size == 3
        partial = 'recent_deck_small'
      elsif size == 2
        partial = 'recent_deck_mid'
      elsif size == 1
        partial = 'recent_deck_large'
      end
      deck_strings = string_hash(decks, user, user.language, 'deck_strings', :deck_id, nil)
      render json: { data: { partials: generate_partials(deck_strings, partial), formats: [:json], layout: false } }
    end
  end

  def rated_decks
    # respective tab is always global when not logged in
    dest = params[:dest]
    search_hash = { global: true }
    value_hash = search_values(params)
    value_hash[:user] = nil
    value_hash[:rated_decks] = true

    # call search service
    decks = policy_scope(deck_search(value_hash, search_hash)).order(updated_at: :desc)

    # return different partials according to number of decks rated
    size = decks.size
    if size == 3
      partial = 'recent_deck_small'
    elsif size == 2
      partial = 'recent_deck_mid'
    elsif size == 1
      partial = 'recent_deck_large'
    end
    deck_strings = string_hash(decks, nil, value_hash[:language], 'deck_strings', :deck_id, nil)
    render json: { data: { partials: generate_partials(deck_strings, partial), formats: [:json], layout: false } }
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

  def string_hash(objects, user, language, string_type, id_type, deck)
    string_hash = {
      objects: objects,
      string_type: string_type,
      id_type: id_type,
      deck: deck,
      language: language
    }
    string_hash[:user] = user unless user.nil?
    string_hash
  end

  def deck_search(value_hash, search_hash)
    DeckSearchService.new(value_hash).call(search_hash)
  end

  def generate_partials(deck_strings, partial_string)
    strings = PopulateStrings.new(deck_strings).call
    array = []
    strings.each do |string|
      ratings = Review.generate_rating(string.deck) # calculate rating score
      card_count = Card.total_cards(string.deck).count
      rating_count = ratings.count
      rating_value = ratings.pluck(:rating).reduce(:+) / rating_count.to_f
      array << render_to_string(
        partial: partial_string,
        locals: { deck_string: string, rating_value: rating_value, rating_count: rating_count, card_count: card_count }
      )
    end
    array
  end

  def search_values(params)
    if params.key?('category')
      string = params['category']['title']
      language = params['category']['language']
      category_ids = params['category']['name']
      tags = params['category']['tag']
    else # account for going straight to /shared_decks
      string = nil
      language = 'en'
      category = Category.find_by(name: 'All Categories')
      category_ids = [category.id]
    end
    { string: string, language: language, categories: category_ids, tags: tags }
  end
end
