// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "trix"
import "@rails/actiontext"

document.addEventListener("turbo:frame-missing", (event) => {
  const { detail: { response, visit } } = event;
  if (response.redirected && response.url.includes("/login")) {
    event.preventDefault();
    visit(response.url)
  }
});
