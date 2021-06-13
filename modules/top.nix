{ pkgs, ... }: {
  environment.etc.topdefaultrc.text = ''
    top's Config File (Linux processes with windows)
    Id:i, Mode_altscr=0, Mode_irixps=1, Delay_time=1.500, Curwin=0
    Def	fieldscur=��K�ŧ�34;=@����6�F)*+,-./128<>?ABCGHIJLMNOPQRSTUVWXYZ[\]^_`abcdefghij
        winflags=161590, sortindx=18, maxtasks=0, graph_cpus=1, graph_mems=2
        summclr=1, msgsclr=1, headclr=3, taskclr=1
    Job	fieldscur=�����(��Ļ�@<��)*+,-./012568>?ABCFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghij
        winflags=163124, sortindx=0, maxtasks=0, graph_cpus=2, graph_mems=0
        summclr=6, msgsclr=6, headclr=7, taskclr=6
    Mem	fieldscur=���<�����MBN�D34��&'()*+,-./0125689FGHIJKLOPQRSTUVWXYZ[\]^_`abcdefghij
        winflags=163124, sortindx=21, maxtasks=0, graph_cpus=2, graph_mems=0
        summclr=5, msgsclr=5, headclr=4, taskclr=5
    Usr	fieldscur=�����������)+,-./1234568;<=>?@ABCFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghij
        winflags=163124, sortindx=3, maxtasks=0, graph_cpus=2, graph_mems=0
        summclr=3, msgsclr=3, headclr=2, taskclr=3
    Fixed_widest=0, Summ_mscale=2, Task_mscale=1, Zero_suppress=0;
  '';

  environment.systemPackages = with pkgs; [
    iotop
  ];

  myHm.programs.htop = {
    enable = true;
    settings = {
      color_scheme = 1;
      tree_view = true;
    };
  };
}
