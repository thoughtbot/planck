# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "securerandom"

RSpec.describe Planck do
  describe ".atomic_write" do
    it "writes new files with 0600 permissions by default" do
      Dir.mktmpdir("planck") do |dir|
        path = File.join(dir, "secret.txt")
        contents = "top secret"

        Planck.atomic_write(path, contents)

        read_back = File.read(path)
        expect(read_back).to eq(contents)
        mode = File.stat(path).mode & 0o777
        expect(mode.to_s(8)).to eq("600")
      end
    end

    context "when overwriting an existing file" do
      it "preserves mode when preserve_mode is truthy" do
        Dir.mktmpdir("planck") do |dir|
          path = File.join(dir, "config.yml")
          File.write(path, "a")
          File.chmod(0o640, path)

          Planck.atomic_write(path, "b", preserve_mode: true)

          expect(File.read(path)).to eq("b")
          mode = File.stat(path).mode & 0o777
          expect(mode.to_s(8)).to eq("640")
        end
      end

      it "proceeds with default permissions if it lacks permission to preserve mode" do
        Dir.mktmpdir("planck") do |dir|
          path = File.join(dir, "config.yml")
          File.write(path, "a")
          File.chmod(0o640, path)

          # Stub chmod to simulate lacking privilege
          allow(File).to receive(:chmod).and_raise(Errno::EPERM)

          Planck.atomic_write(path, "b", preserve_mode: true)

          expect(File.read(path)).to eq("b")
          mode = File.stat(path).mode & 0o777
          expect(mode.to_s(8)).to eq("600")
        end
      end

      it "does not preserve mode when preserve_mode is falsy (default)" do
        Dir.mktmpdir("planck") do |dir|
          path = File.join(dir, "config.yml")
          File.write(path, "a")
          File.chmod(0o640, path)

          Planck.atomic_write(path, "b")

          mode = File.stat(path).mode & 0o777
          expect(mode.to_s(8)).to eq("600")
        end
      end
    end

    it "replaces an existing file atomically and leaves no temp files around" do
      Dir.mktmpdir("planck") do |dir|
        path = File.join(dir, "config.json")
        original = '{"a":1}'
        updated  = '{"a":2,"b":3}'

        File.write(path, original)

        Planck.atomic_write(path, updated)

        expect(File.read(path)).to eq(updated)
        hidden_name_prefix = ".#{File.basename(path)}"
        leftovers = Dir.children(dir).select { |n| n.start_with?(hidden_name_prefix) }
        expect(leftovers).to be_empty
      end
    end

    it "is whole-or-nothing under contention (no partial reads observed)" do
      Dir.mktmpdir("planck") do |dir|
        path = File.join(dir, "log.txt")
        a = "A" * 10_000          # distinct sizes make partials easy to spot
        b = "B" * 7_000

        File.write(path, "start")

        stop = false
        seen = Queue.new

        reader = Thread.new do
          while !stop
            begin
              data = File.read(path)
              seen << data
            rescue Errno::ENOENT
              # File may not exist before first write; ignore
            end
          end
        end

        writer1 = Thread.new do
          100.times { Planck.atomic_write(path, a) }
        end
        writer2 = Thread.new do
          100.times { Planck.atomic_write(path, b) }
        end

        [writer1, writer2].each(&:join)
        stop = true
        reader.join

        # Every observed read must be exactly one of the full strings (never a mix/truncate)
        until seen.empty?
          data = seen.pop
          expect([a, b, "start"]).to include(data)
        end
      end
    end

    it "propagates errors when directory does not exist" do
      non_existent_dir = File.join(Dir.tmpdir, "planck-missing-#{SecureRandom.hex(4)}")
      path = File.join(non_existent_dir, "secret.txt")
      contents = "x"

      expect {
        Planck.atomic_write(path, contents)
      }.to raise_error(Errno::ENOENT)
    end
  end
end
