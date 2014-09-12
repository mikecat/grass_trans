#!/usr/bin/perl

use strict;

# The global stack
my %global_stack = (
	"Out" => 3,
	"Succ" => 2,
	"w" => 1,
	"In" => 0
);
# The number of elements int the global stack
my $global_counter = 4;

# Local stack for function definition
my %local_stack = ();
my $local_counter = 0;

# Flag: Is this line in function definition?
my $define_mode = 0;
# The name of function currently defining
my $defining_name = "";
# Flag: Is v required if program continues?
#  0 : not needed
#  1 ; needed if next command if a function definition
#  2 : needed
my $need_v = 0;

# Nest level of block comments.
my $comment_count = 0;

# Characters per line
my $line_characters = 79;
# Number of characters in current line
my $line_count = 0;
# Number of characters printed (except new line)
my $character_count = 0;
# Flag: Is the next non-empty line the first program?
my $first_line = 1;

if (@ARGV > 0) {
	$line_characters = int($ARGV[0]);
}

for (my ($line_count, $line) = (1, ""); $line = <STDIN>; $line_count++) {
	chomp($line);
	# Remove leading spaces.
	$line =~ s/\A[ \t]+//;
	# Remove comments.
	$line =~ s/(#|--|%|\/\/|').*\z//;
	# Skip parsing an empty line.
	if ($line eq "") {next;}
	# Split by spaces.
	my @parts = split(/[ \t]+/, $line);

	# Deal with block comments.
	if ($parts[0] eq "comment_begin") {
		if (@parts > 0) {
			warn "Extra string exists after comment_begin at line $line_count\n";
		}
		$comment_count++;
	} elsif ($parts[0] eq "commend_end") {
		if (@parts > 0) {
			warn "Extra string exists after comment_end at line $line_count\n";
		}
		if ($comment_count <= 0) {
			warn "comment_end appeared without corresponding comment_begin at line $line_count\n";
		} else {
			$comment_count--;
			next;
		}
	}

	if ($comment_count > 0) {next;}

	if ($parts[0] eq "function") {
		# Enter to function definition.
		if ($define_mode != 0) {
			warn "nested function definition not allowed at line $line_count\n";
		}
		if (@parts < 2) {
			warn "function definition requires the name of function at line $line_count\n";
		}
		if (@parts < 3) {
			warn "function definition requires at least one argument at line $line_count\n";
		}
		if ($need_v >= 1) {&print_chars("v", 1);}
		# Print the number of arguments.
		&print_chars("w", @parts - 2);
		# Register arguments for local stack.
		$local_counter = $global_counter;
		%local_stack = ();
		for (my $i = 2; $i < @parts; $i++) {
			$local_stack{$parts[$i]} = ($local_counter++);
		}
		$define_mode = 1;
		$defining_name = $parts[1];
		$need_v = 0;
	} elsif ($parts[0] eq "endfunction") {
		# Leave function definition.
		if ($define_mode == 0) {
			warn "endfunction without function at line $line_count\n";
		}
		$global_stack{$defining_name} = ($global_counter++);
		$define_mode = 0;
		$need_v = 2;
	} elsif ($parts[0] eq "rename") {
		# Give a new name for a data.
		if ((@parts != 3 && @parts != 4) || (@parts == 4 && $parts[2] ne "=")) {
			warn "invalid syntax for rename at line $line_count\n";
		} else {
			my ($from, $to);
			if (@parts == 3) {
				# mv/cp command format
				$from = $parts[1];
				$to = $parts[2];
			} else {
				# assignment format
				$from = $parts[3];
				$to = $parts[1];
			}
			if ($define_mode != 0) {
				my $current_index = $local_stack{$from};
				if (!defined($current_index)) {
					$current_index = $global_stack{$from};
				}
				if (!defined($current_index)) {
					warn "identifier $from undefined at line $line_count\n";
				} else {
					$local_stack{$to} = $current_index;
				}
			} else {
				my $current_index = $global_stack{$from};
				if (!defined($current_index)) {
					warn "identifier $from undefined at line $line_count\n";
				} else {
					$global_stack{$to} = $current_index;
				}
			}
		}
	} else {
		# Function application
		if ($need_v >= 2) {&print_chars("v", 1);}
		if ($first_line != 0) {
			warn "function definition must come first at line $line_count\n";
		}
		if (@parts < 2 || ($parts[1] eq "=" && @parts < 3)) {
			warn "function application requires at least one argument at line $line_count\n";
		}
		my $offset = ($parts[1] eq "=" ? 2 : 0);
		if ($define_mode != 0) {
			# In function definition
			$local_stack{"it"} = $local_counter - 1;
			for (my $i = 0; $i + $offset < @parts; $i++) {
				my $current_part = $parts[$i + $offset];
				my $current_index;
				$current_index = $local_stack{$current_part};
				if (!defined($current_index)) {
					$current_index = $global_stack{$current_part};
				}
				if (!defined($current_index)) {
					warn "identifier $current_part undefined at line $line_count\n";
					$current_index = $local_counter;
				}
				if ($i == 0) {
					&print_chars("W", $local_counter - $current_index);
				} else {
					if ($i > 1) {&print_chars("W", 1);}
					&print_chars("w", $local_counter - $current_index);
					$local_counter++;
				}
			}
			if ($parts[1] eq "=") {
				$local_stack{$parts[0]} = $local_counter - 1;
			}
		} else {
			# Out of function definition
			$global_stack{"it"} = $global_counter - 1;
			for (my $i = 0; $i + $offset < @parts; $i++) {
				my $current_part = $parts[$i + $offset];
				my $current_index;
				$current_index = $global_stack{$current_part};
				if (!defined($current_index)) {
					warn "identifier $current_part undefined at line $line_count\n";
					$current_index = $global_counter;
				}
				if ($i == 0) {
					&print_chars("W", $global_counter - $current_index);
				} else {
					if ($i > 1) {&print_chars("W", 1);}
					&print_chars("w", $global_counter - $current_index);
					$global_counter++;
				}
			}
			if ($parts[1] eq "=") {
				$global_stack{$parts[0]} = $global_counter - 1;
			}
		}
		$need_v = 1;
	}
	$first_line = 0;
}

if ($define_mode != 0) {
	warn "unterminated function definithon at end of input\n";
}
if ($comment_count > 0) {
	warn "unterminated block comment at end of input\n";
}

if ($line_count > 0) {print "\n";}
warn "total $character_count character(s) printed.\n";

# Output spesified character number times.
sub print_chars {
	my ($char, $number) = @_;
	while ($number > 0) {
		# Retrieve the number to print
		my $current_number = $line_characters - $line_count;
		if ($current_number > $number) {$current_number = $number;}
		# Print it
		print $char x $current_number;
		# Count printed characters
		$number -= $current_number;
		$line_count += $current_number;
		$character_count += $current_number;
		# Go to new line if needed
		if ($line_count >= $line_characters) {
			$line_count -= $line_characters;
			print "\n";
		}
	}
	return "";
}
