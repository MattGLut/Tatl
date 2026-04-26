import { application } from "controllers/application"

// Eager load all controllers in this directory
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
