use Modern::Perl;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/..";

use C4::Context;
use Koha::Suggestion;
use Koha::Plugin::Com::AJSN::PromotionEngagement;
use Koha::Plugin::Com::AJSN::PromotionEngagement::BookDisplayImpact;

my $dbh = C4::Context->dbh;
$dbh->{RaiseError} = 1;
my $plugin = Koha::Plugin::Com::AJSN::PromotionEngagement->new(
    { enable_plugins => 1 }
);
$plugin->_ensure_schema;
$dbh->begin_work;

my ($biblionumber) = $dbh->selectrow_array(
    q{SELECT i.biblionumber FROM plugin_ajsn_promo_items pi
      JOIN items i ON i.itemnumber=pi.itemnumber
      WHERE pi.campaign_id=40 AND pi.deleted_at IS NULL LIMIT 1}
);
ok( $biblionumber, 'BDI-01 campaign 40 resolves a displayed biblio' );
my ($branchcode) = $dbh->selectrow_array(
    q{SELECT branchcode FROM borrowers WHERE borrowernumber=51}
);
for my $priority ( 1 .. 7 ) {
    $dbh->do(
        q{INSERT INTO reserves
          (borrowernumber,reservedate,biblionumber,branchcode,priority)
          VALUES (51,CURDATE(),?,?,?)},
        undef, $biblionumber, $branchcode, $priority,
    );
}
$dbh->do(
    q{INSERT INTO old_issues
      (issue_id,borrowernumber,itemnumber,issuedate,renewals_count)
      VALUES (991040,51,1,'2026-09-20 10:00:00',0)}
);

my $service =
  Koha::Plugin::Com::AJSN::PromotionEngagement::BookDisplayImpact->new(
    { dbh => $dbh }
  );
my $result = $service->campaign_rows(40);
is( $result->{spec_version}, '1.0.0', 'BDI-02 specification version returned' );
is( $result->{summary}->{title_count}, 1, 'BDI-03 biblio-level aggregation returned' );
my $row = $result->{rows}->[0];
is( $row->{biblionumber}, $biblionumber, 'BDI-04 Koha biblio retained' );
cmp_ok( $row->{active_holds}, '>=', 7, 'BDI-05 active holds counted' );
cmp_ok( $row->{serviceable_copies}, '>=', 1, 'BDI-06 serviceable copies counted' );
cmp_ok( $row->{hold_ratio}, '>', 0, 'BDI-07 hold pressure calculated' );
is( $row->{priority}, 'High', 'BDI-08 demand classified high priority' );
is( $row->{evidence_grade}, 'Strong', 'BDI-09 circulation plus holds is strong evidence' );
cmp_ok( $row->{suggested_quantity}, '>=', 1, 'BDI-10 additional-copy quantity suggested' );

$dbh->do(
    q{INSERT INTO plugin_ajsn_promo_recommendations
      (campaign_id,biblionumber,decision_status,recommended_quantity,
       reviewer_note,decided_by,decided_at)
      VALUES (40,?,'approved',2,'BDI test approval',51,NOW())},
    undef, $biblionumber,
);
my $approved = $service->campaign_rows(40)->{rows}->[0];
is( $approved->{decision}->{decision_status}, 'approved',
    'BDI-11 approved decision is returned' );
is( $approved->{decision}->{recommended_quantity}, 2,
    'BDI-12 reviewed quantity is preserved' );

my $suggestion = Koha::Suggestion->new( {
    suggestedby => 51,
    title => $row->{title},
    author => $row->{author},
    biblionumber => $biblionumber,
    branchcode => $branchcode,
    quantity => 2,
    STATUS => 'ASKED',
    patronreason => 'BDI integration test',
} )->store;
ok( $suggestion->suggestionid, 'BDI-13 native Koha suggestion created' );
is( $suggestion->STATUS, 'ASKED', 'BDI-14 native suggestion enters pending state' );
is( $suggestion->quantity, 2, 'BDI-15 native suggestion retains quantity' );
is( $suggestion->biblionumber, $biblionumber,
    'BDI-16 native suggestion links existing Koha title' );

$dbh->rollback;
pass('BDI-17 synthetic holds, decision and suggestion rolled back');
done_testing;
