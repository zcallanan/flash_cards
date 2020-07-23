import { Controller } from "stimulus"
import { fetchWithToken } from '../utils/fetch_with_token.js';
import { isVisible } from '../utils/is_visible.js';
import { buildSearchUrl } from '../utils/build_search_url.js';
import { searchSetup } from "../utils/search_setup.js"

export default class extends Controller {
  static targets = [
    'globalDiv',
    'myDecksDiv',
    'myArchivedDiv',
    'sharedReadDiv',
    'sharedUpdateDiv',
    'searchSubmit',
    'categorySelect',
    'languageSelect',
    'tagSelect',
    'option',
    'indexDiv',
    'categorySelect',
    'searchForm',
    'titleString',
    'allDecks',
    'myDecks',
    'sharedDecks'
  ]

  connect() {

    const allDecks = this.allDecksTarget;
    const myDecks = this.myDecksTarget;
    const sharedDecks = this.sharedDecksTarget;
    const titleString = this.titleStringTarget;
    const searchForm = this.searchFormTarget;
    const globalDiv = this.globalDivTarget;
    const myDecksDiv = this.myDecksDivTarget;
    const myArchivedDiv = this.myArchivedDivTarget;
    const sharedReadDiv = this.sharedReadDivTarget;
    const sharedUpdateDiv = this.sharedUpdateDivTarget;
    const categorySelect = this.categorySelectTarget;
    const languageSelect = this.languageSelectTarget;
    const tagSelect = this.tagSelectTarget;
    const searchSubmit = this.searchSubmitTarget;
    const urlRoute = 'http://localhost:3000/api/v1/decks/';
    let dest = '';
    let destTwo = '';
    let divTwo = '';
    let searchValues = {};
    let searchValuesTwo = {}
    const targets = [allDecks, myDecks, sharedDecks, searchSubmit]
    // initializes deck index Choices.js fields
    const [categoryChoices, languageChoices, tagChoices] = searchSetup(categorySelect, languageSelect, tagSelect, searchForm.dataset.con)
    const tag_options = Array.from(tagSelect.children).map(option => option.value)
    const category_options = Array.from(categorySelect.children).map(option => option.value)

    if (isVisible(globalDiv)) {
      dest = 'global';
      searchValues['div'] = globalDiv
      destTwo = null;
    } else if (isVisible(myDecksDiv)) {
      dest = 'mydecks';
      searchValues['div'] = myDecksDiv
      destTwo = 'myarchived';
      divTwo = myArchivedDiv;
    } else if (isVisible(sharedReadDiv)) {
      dest = 'shared_read'
      searchValues['div'] = sharedReadDiv
      destTwo = 'shared_update';
      divTwo = sharedUpdateDiv;
    }

    let search_url = {
      options: category_options,
      language: languageSelect.value,
      string: titleString.value,
      tag: tag_options,
      urlRoute: urlRoute,
      dest: dest
    };

    searchValues['url'] = buildSearchUrl(search_url);
    this.search(searchValues);

    if (destTwo !== null) {
      search_url = {
        options: category_options,
        language: languageSelect.value,
        string: titleString.value,
        tag: tag_options,
        urlRoute: urlRoute,
        dest: destTwo
      };
      searchValuesTwo['div'] = divTwo;
      searchValuesTwo['url'] = buildSearchUrl(search_url);
      this.search(searchValuesTwo);
    }

    targets.forEach((target) => {
      target.addEventListener('click', (event) => {
        event.preventDefault();
        if (event.target === allDecks && !allDecks.classList.contains('active')) {
          // if user clicks on All Decks and it is not the active tab
          globalDiv.style.display = 'block';
          myDecksDiv.style.display = 'none';
          myArchivedDiv.style.display = 'none';
          sharedReadDiv.style.display = 'none';
          sharedUpdateDiv.style.display = 'none';
          if (myDecks.classList.contains('active')) myDecks.classList.remove('active')
          if (sharedDecks.classList.contains('active')) sharedDecks.classList.remove('active')
          allDecks.classList.add('active');
          const allTabValues = {
            url: 'http://localhost:3000/api/v1/decks/global', // click on the tab and you get all global items available
            div: globalDiv
          }
          this.search(allTabValues)
        } else if (event.target === myDecks && !myDecks.classList.contains('active')) {
          globalDiv.style.display = 'none';
          myDecksDiv.style.display = 'block';
          myArchivedDiv.style.display = 'block';
          sharedReadDiv.style.display = 'none';
          sharedUpdateDiv.style.display = 'none';
          if (allDecks.classList.contains('active')) allDecks.classList.remove('active')
          if (sharedDecks.classList.contains('active')) sharedDecks.classList.remove('active')
          myDecks.classList.add('active');
          let allTabValues = {
            url: 'http://localhost:3000/api/v1/decks/mydecks', // click on the tab and you get all mydeck items available
            div: myDecksDiv
          }
          this.search(allTabValues)
          allTabValues = {
            url: 'http://localhost:3000/api/v1/decks/myarchived',
            div: myArchivedDiv
          }
          this.search(allTabValues)
        } else if (event.target === sharedDecks && !sharedDecks.classList.contains('active')) {
          globalDiv.style.display = 'none';
          myDecksDiv.style.display = 'none';
          myArchivedDiv.style.display = 'none';
          sharedReadDiv.style.display = 'block';
          sharedUpdateDiv.style.display = 'block';
          if (allDecks.classList.contains('active')) allDecks.classList.remove('active')
          if (myDecks.classList.contains('active')) myDecks.classList.remove('active')
          sharedDecks.classList.add('active');
          let allTabValues = {
            url: 'http://localhost:3000/api/v1/decks/shared_read', // click on the tab and you get all shared items available
            div: sharedReadDiv
          }
          this.search(allTabValues)
          allTabValues = {
            url: 'http://localhost:3000/api/v1/decks/shared_update',
            div: sharedUpdateDiv
          }
          this.search(allTabValues)
        } else if (event.target === searchSubmit) {

          const tag_options = Array.from(tagSelect.children).map(option => option.value)
          const category_options = Array.from(categorySelect.children).map(option => option.value)

          if (isVisible(globalDiv)) {
            dest = 'global';
            searchValues['div'] = globalDiv;
            destTwo = null;
          } else if (isVisible(myDecksDiv)) {
            dest = 'mydecks';
            searchValues['div'] = myDecksDiv;
            destTwo = 'myarchived';
            divTwo = myArchivedDiv;
          } else if (isVisible(sharedReadDiv)) {
            dest = 'shared_read';
            searchValues['div'] = sharedReadDiv;
            destTwo = 'shared_update';
            divTwo = sharedUpdateDiv;
          }

          let search_url = {
            options: category_options,
            language: languageSelect.value,
            string: titleString.value,
            tag: tag_options,
            urlRoute: urlRoute,
            dest: dest
          };

          searchValues['url'] = buildSearchUrl(search_url);
          this.search(searchValues);

          if (destTwo !== null) {
            const tag_options = Array.from(tagSelect.children).map(option => option.value)
            const category_options = Array.from(categorySelect.children).map(option => option.value)
            search_url = {
              options: category_options,
              language: languageSelect.value,
              string: titleString.value,
              tag: tag_options,
              urlRoute: urlRoute,
              dest: destTwo
            };
            searchValuesTwo['div'] = divTwo;
            searchValuesTwo['url'] = buildSearchUrl(search_url);
            this.search(searchValuesTwo);
          }
        }
      })
    })
  }

  search(values) {
    fetchWithToken(values.url, {
      method: "GET",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json"
      }
    })
      .then(response => response.json())
      .then((data) => {
        values.div.innerHTML = ''
        values.div.innerHTML = data['data']['partials'].join('')
      });
  }
}


