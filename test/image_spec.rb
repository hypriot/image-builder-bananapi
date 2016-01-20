require 'serverspec'
set :backend, :exec

describe "SD-Card Image" do
  let(:image_path) { return '/sd-card-rpi.img' }

  it "exists" do
    image_file = file(image_path)

    expect(image_file).to exist
  end

  context "Partition table" do
    let(:stdout) { command("guestfish add #{image_path} : run : list-filesystems").stdout }

    it "has two partitions" do
      partitions = stdout.split(/\r?\n/)

      expect(partitions.size).to be 2
    end

    it "has a boot-partition with a vfat filesystem" do
      expect(stdout).to contain('sda1: vfat')
    end

    it "has a root-partition with a ext4 filesystem" do
      expect(stdout).to contain('sda2: ext4')
    end
  end

  context "Root filesystem" do
    let(:stdout) { command("guestfish add #{image_path} : run : mount /dev/sda2 / : cat /etc/os-release").stdout }

    it "is based on debian" do
      expect(stdout).to contain('debian')
    end

    it "is debian version jessie" do
      expect(stdout).to contain('jessie')
    end

    it "is a HypriotOS" do
      expect(stdout).to contain('HypriotOS')
    end
  end

  context "Binary dpkg" do
    let(:stdout) { command("guestfish add #{image_path} : run : mount /dev/sda2 / : file-architecture /usr/bin/dpkg").stdout }

    it "is compiled for ARM architecture" do
      expect(stdout).to contain('arm')
    end
  end

  context "Binary vi" do
    let(:stdout) { command("guestfish add #{image_path} : run : mount /dev/sda2 / : file-architecture /usr/bin/dpkg").stdout }

    it "is compiled for ARM architecture" do
      expect(stdout).to contain('arm')
    end
  end

  context "/etc/fstab" do
    let(:stdout) { command("guestfish add #{image_path} : run : mount /dev/sda2 / : cat /etc/fstab").stdout }

    it "has a vfat boot entry" do
      expect(stdout).to contain('/dev/mmcblk0p1 /boot vfat')
    end

    it "has a ext4 root entry" do
      expect(stdout).to contain('/dev/mmcblk0p2 / ext4')
    end
  end
end
