# frozen_string_literal: true

require 'rails_helper'

describe StatusLengthValidator do
  describe '#validate' do
    it 'does not add errors onto remote statuses' do
      status = double(local?: false)
      subject.validate(status)
      expect(status).not_to receive(:errors)
    end

    it 'does not add errors onto local reblogs' do
      status = double(local?: false, reblog?: true)
      subject.validate(status)
      expect(status).not_to receive(:errors)
    end

    it 'adds an error when content warning is over 1000 characters' do
      status = double(spoiler_text: 'a' * 1040, text: '', errors: double(add: nil), local?: true, reblog?: false)
      subject.validate(status)
      expect(status.errors).to have_received(:add)
    end

    it 'adds an error when text is over 1000 characters' do
      status = double(spoiler_text: '', text: 'a' * 1040, errors: double(add: nil), local?: true, reblog?: false)
      subject.validate(status)
      expect(status.errors).to have_received(:add)
    end

    it 'adds an error when text and content warning are over 1000 characters total' do
      status = double(spoiler_text: 'a' * 500, text: 'b' * 501, errors: double(add: nil), local?: true, reblog?: false)
      subject.validate(status)
      expect(status.errors).to have_received(:add)
    end

    it 'counts URLs as 23 characters flat' do
      text   = ('a' * 976) + " http://#{'b' * 30}.com/example"
      status = double(spoiler_text: '', text: text, errors: double(add: nil), local?: true, reblog?: false)

      subject.validate(status)
      expect(status.errors).to_not have_received(:add)
    end

    it 'does not count non-autolinkable URLs as 23 characters flat' do
      text   = ('a' * 476) + "http://#{'b' * 30}.com/example"
      status = double(spoiler_text: '', text: text, errors: double(add: nil), local?: true, reblog?: false)

      subject.validate(status)
      expect(status.errors).to have_received(:add)
    end

    it 'does not count overly long URLs as 23 characters flat' do
      text = "http://example.com/valid?#{'#foo?' * 1000}"
      status = double(spoiler_text: '', text: text, errors: double(add: nil), local?: true, reblog?: false)
      subject.validate(status)
      expect(status.errors).to have_received(:add)
    end

    it 'counts only the front part of remote usernames' do
      text   = ('a' * 975) + " @alice@#{'b' * 30}.com"
      status = double(spoiler_text: '', text: text, errors: double(add: nil), local?: true, reblog?: false)

      subject.validate(status)
      expect(status.errors).to_not have_received(:add)
    end

    it 'does count both parts of remote usernames for overly long domains' do
      text   = "@alice@#{'b' * 500}.com"
      status = double(spoiler_text: '', text: text, errors: double(add: nil), local?: true, reblog?: false)

      subject.validate(status)
      expect(status.errors).to have_received(:add)
    end
  end
end
