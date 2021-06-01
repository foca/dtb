# frozen_string_literal: true

module DTB
  # Mixin for other errors raised from this library, so that you can always
  # catch DTB::Error.
  module Error; end

  # Raised when initializing an object that supports options with an option that
  # hasn't been defined. See HasOptions.
  class UnknownOptionsError < ArgumentError
    include DTB::Error

    attr_reader :options
    attr_reader :valid_options
    attr_reader :unknown_options

    def initialize(options, valid_options)
      unknown = options.keys.to_set - valid_options
      super(format(MESSAGE, unknown.to_a, valid_options.to_a))
      @options = options
      @valid_options = valid_options
      @unknown_options = unknown
    end

    MESSAGE = "Unknown options: %p. Valid options are: %p"
  end

  class MissingOptionsError < ArgumentError
    include DTB::Error

    attr_reader :options
    attr_reader :required_options
    attr_reader :missing_options

    def initialize(options, required_options)
      missing = required_options - options.keys
      super(format(MESSAGE, missing.to_a, options.to_a))
      @options = options
      @required_options = required_options
      @missing_options = missing
    end

    MESSAGE = "Missing required options: %p. Options given were: %p"
  end

  # Extends NotImplementedException to be catchable as a library error via
  # `rescue DTB::Error`. Normally you wouldn't rescue this in code, though,
  # but rather use it to get failing tests / exceptions while developing.
  #
  # rubocop:disable Lint/InheritException
  class NotImplementedError < ::NotImplementedError
    include DTB::Error
  end
  # rubocop:enable Lint/InheritException
end
