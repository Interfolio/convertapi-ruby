RSpec.describe ConvertApi::Task do
  let(:task) { described_class.new(from_format, to_format, params) }
  let(:from_format) { 'txt' }
  let(:to_format) { 'pdf' }
  let(:params) { { File: 'https://www.w3.org/TR/2003/REC-PNG-20031110/iso_8859-1.txt' } }

  describe '#run' do
    subject { task.run }

    let(:result) { double }

    it 'executes task and returns result' do
      expect(ConvertApi.client).to(
        receive(:post).with('convert/txt/to/pdf', instance_of(Hash), instance_of(Hash)).and_return(result)
      )

      expect(subject).to be_instance_of(ConvertApi::Result)
    end

    describe 'async' do
      let(:params) { { Async: true, File: 'https://www.w3.org/TR/2003/REC-PNG-20031110/iso_8859-1.txt' } }

      it 'submits an async task and returns result' do
        expect(ConvertApi.client).to(
          receive(:post).with('async/convert/txt/to/pdf', instance_of(Hash), instance_of(Hash)).and_return(result)
        )

        expect(subject).to be_instance_of(ConvertApi::AsyncResult)
      end
    end
  end
end
