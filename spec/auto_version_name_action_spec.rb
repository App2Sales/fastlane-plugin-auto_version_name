describe Fastlane::Actions::AutoVersionNameAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The auto_version_name plugin is working!")

      Fastlane::Actions::AutoVersionNameAction.run(nil)
    end
  end
end
