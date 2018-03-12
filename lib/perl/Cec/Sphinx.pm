package Cec::Sphinx;

use Proc::ProcessTable;

sub is_search_up {
  my $t = Proc::ProcessTable->new( 'cache_ttys' => 1 );
  foreach my $p ( @{$t->table} ){
    my $cmd=$p->cmndline // next;
    if($cmd=~m|searchd|) {
      return 1;
    }
    # print "$cmd\n";
  }
  return 0;
}

sub make_sure_its_up {
  if(&is_search_up) {
    return 0;
  }
  &start();
}

sub start {
  system("sudo searchd");
}

sub stop {
  system("killall searchd");
}

1;
