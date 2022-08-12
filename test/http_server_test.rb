# frozen_string_literal: true

require '../lib/birth'

TEST_ROUTES = {
  :/ => {
    GET: 'test'
  }
}.freeze

HTTPServer.listen(3000, TEST_ROUTES)
