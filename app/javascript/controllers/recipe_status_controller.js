import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { status: String }

  connect() {
    if (["pending", "processing"].includes(this.statusValue)) {
      setTimeout(() => window.location.reload(), 2000)
    }
  }
}
