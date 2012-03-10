use strict;
use bytes;
use File::Find;
use Fcntl ':mode';

# Check args
die "makeFlash.pl <web_root_directory>\n" if scalar(@ARGV) != 1;
die "Error: $ARGV[0] is not a directory\n" if not -d $ARGV[0];

# Open the flash image file and set it to binary mode
open( OUTPUT, ">webpage_bin.img");
open( LOC, ">copy_to_httpd.txt");
binmode(OUTPUT);

# Change to the root of the web file system
chdir( $ARGV[0] );

# Get a list of all files
my @files;
find( sub { push @files, substr($File::Find::name, 2) if not -d $File::Find::name }, ( "." ) );

# Get initial page counter
my $pageoffset = 0;

# Loop over all files
foreach my $file ( @files ) {

  # Decide on the mime type
  my $mimetype = "";
  $mimetype = "text/html" if $file =~ /.*\.htm(l?)/;
  $mimetype = "image/$1" if $file =~ /.*\.(jpeg|gif|png)/;
  next if $mimetype eq "";

  # Read the complete file
  local( $/, *FH ) ;
  open( FH, $file ) or die "sudden flaming death\n";
  my $filedata = <FH>;

  # Construct header (must be constructed exactly)
  my $blob = "HTTP/1.0 200 OK\r\nServer: XMOS\r\nContent-type: $mimetype\r\n\r\n";

  # Append the file data
  $blob .= $filedata;

  # Get length of the blob
  my $blob_length = length($blob);

  # Get number of pages blob sits in (expression (x+255)/256 rounds up to nearest page)
  my $num_pages = int(($blob_length + 255) / 256);

  # Append padding to take blob to an integral number of pages in length
  $blob .= "\0" x (($num_pages * 256) - $blob_length);

  # Write out the data blob
  print OUTPUT $blob;

  # Print out this files flash image info
  print (LOC "{ \"/$file\", $pageoffset, $blob_length },\n");

  # Keep track of which page we are up to
  $pageoffset += $num_pages;
}




