package Inventory;

use strict;
use warnings;

#Target types to always include in the inventory if present
my %TYPES = (SYS => 1, NODE => 1, PROC => 1, BMC => 1, GPU => 1);

#RU_TYPES of cards to include
#FRU = field replaceable unit, CRU = customer replaceable unit
my %RU_TYPES = (FRU => 1, CRU => 1);

#Returns an array of hashes that represents the inventory
#for a system.  The hash elements are:
#TARGET:  The MRW target of the item
#OBMC_NAME: The OpenBMC name for the item.  This is usually
#           a simplified version of the target.
sub getInventory
{
    my $targetObj = shift;
    my @inventory;

    if (ref($targetObj) ne "Targets") {
        die "Invalid Targets object passed to getInventory\n";
    }

    findItems($targetObj, \@inventory);

    return @inventory;
}


#Finds the inventory targets in the MRW.
#It selects them if the target's type is in %TYPES
#or the target's RU_TYPE is in %RU_TYPES.
#This will pick up FRUs and other chips like the BMC and processor.
sub findItems
{
    my ($targetObj, $inventory) = @_;

    for my $target (sort keys %{$targetObj->getAllTargets()}) {
        my $type = "";
        my $ruType = "";

        if (!$targetObj->isBadAttribute($target, "TYPE")) {
            $type = $targetObj->getAttribute($target, "TYPE");
        }

        if (!$targetObj->isBadAttribute($target, "RU_TYPE")) {
            $ruType = $targetObj->getAttribute($target, "RU_TYPE");
        }

        if ((exists $TYPES{$type}) || (exists $RU_TYPES{$ruType})) {
            my %item;
            $item{TARGET} = $target;
            $item{OBMC_NAME} = $target; #Will fixup later
            push @$inventory, { %item };
        }
    }
}


1;

=head1 NAME

Inventory

=head1 DESCRIPTION

Retrieves the OpenBMC inventory from the MRW.

The inventory contains:

=over 4

=item * The system target

=item * The chassis target(s)  (Called a 'node' in the MRW.)

=item * All targets of class CARD or CHIP that are FRUs.

=item * All targets of type PROC

=item * All targets of type BMC

=item * All targets of type GPU

=back

=head2 Notes:

The processor and GPU chips are usually modeled in the MRW as a
card->chip package that would plug into a connector on the motherboard
or other parent card.  So, even if both card and chip are marked as a FRU,
there will only be 1 entry in the inventory for both, and the MRW
target associated with it will be for the chip and not the card.

In addition, this intermediate card will be removed from the path name:
  /system/chassis/motheboard/cpu and not
  /system/chassis/motherboard/cpucard/cpu

=head2 Inventory naming conventions

The inventory names returned in the OBMC_NAME hash element will follow
the conventions listed below.  An example of an inventory name is:
/system/chassis/motherboard/cpu5

=over 4

=item * If there is only 1 instance of any segment in the system, then
        it won't have an instance number, otherwise there will be one.

=item * The root of the name is '/system'.

=item * After system is 'chassis', of which there can be 1 or more.

=item * The name is based on the MRW card plugging order, and not what
        the system looks like from the outside.  For example, a power
        supply that plugs into a motherboard (maybe via a non-fru riser
        or cable, see the item below), would be:
        /system/chassis/motherboard/psu2 and not
        /system/chassis/psu2.

=item * If a card is not a FRU so isn't in the inventory itself, then it
        won't show up in the name of any child cards that are FRUs.
        For example, if fan-riser isn't a FRU, it would be
        /system/chassis/motherboard/fan3 and not
        /system/chassis/motherboard/fan-riser/fan3.

=item * The MRW models connectors between cards, but these never show up
        in the inventory name.

=item * If there is a motherboard, it is always called 'motherboard'.

=item * Processors, GPUs, and BMCs are always called: 'cpu', 'gpu' and
        'bmc' respectively.

=back

=head1 METHODS

=over 4

=item getInventory (C<TargetsObj>)

Returns an array of hashes representing inventory items.

The Hash contains:

* TARGET: The MRW target of the item, for example:

    /sys-0/node-0/motherboard-0/proc_socket-0/module-0/p9_proc_m

* OBMC_NAME: The OpenBMC name of the item, for example:

   /system/chassis/motherboard/cpu2

=back

=cut
