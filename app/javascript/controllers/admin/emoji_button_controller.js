import { Controller } from "@hotwired/stimulus"
import { EmojiButton } from "@joeattardi/emoji-button"
import deEmojiData from '@roderickhsiao/emoji-button-locale-data/dist/de'
import frEmojiData from '@roderickhsiao/emoji-button-locale-data/dist/fr'
import itEmojiData from '@roderickhsiao/emoji-button-locale-data/dist/it'

export default class extends Controller {
  static get targets() {
    return ["button"]
  }

  connect() {
    const locale = document.documentElement.lang

    var localeEmojiData;
    if (locale === 'de') {
      localeEmojiData = deEmojiData;
    } else if (locale === 'fr') {
      localeEmojiData =  frEmojiData;
    } else if (locale === 'it') {
      localeEmojiData = itEmojiData;
    }

    const prefersDarkScheme = window.matchMedia("(prefers-color-scheme: dark)").matches
    const hasDarkClass = document.documentElement.classList.contains("dark")
    const useDarkTheme = prefersDarkScheme || hasDarkClass
    const theme = useDarkTheme ? 'dark' : 'light'

    this.application.picker = new EmojiButton({
      theme: theme,
      initialCategory: 'food',
      showRecents: false,
      emojisPerRow: 8,
      rows: 8,
      position: 'bottom-start',
      emojiData: localeEmojiData
    })

    this.application.picker.on('emoji', selection => {
      this.buttonTarget.value = selection.emoji;
    })
  }

  disconnect() {
    this.application.picker.destroyPicker()
  }

  toggle() {
    this.application.picker.togglePicker(this.buttonTarget)
  }
}
