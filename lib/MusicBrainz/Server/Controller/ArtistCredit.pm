package MusicBrainz::Server::Controller::ArtistCredit;
use Moose;
use Moose::Util qw( find_meta );

BEGIN { extends 'MusicBrainz::Server::Controller' }

use MusicBrainz::Server::Data::Utils qw( type_to_model );
use MusicBrainz::Server::Constants qw( %ENTITIES entities_with );
use MusicBrainz::Server::ControllerUtils::JSON qw( serialize_pager );

__PACKAGE__->config(
    namespace   => 'artist_credit',
);

with 'MusicBrainz::Server::Controller::Role::Load' => {
    model => 'ArtistCredit',
};

sub base : Chained('/') PathPart('artist-credit') CaptureArgs(0) { }

sub _load
{
    my ($self, $c, $id) = @_;
    my $artist_credit = $c->model('ArtistCredit')->get_by_id($id);
    return $artist_credit;
}

sub show : Chained('load') PathPart('')
{
    my ($self, $c) = @_;
    my $artist_credit = $c->stash->{artist_credit};
    $c->stash(
        current_view => 'Node',
        component_path => 'artist_credit/ArtistCreditIndex',
        component_props => {
            %{$c->stash->{component_props}},
            artistCredit => $artist_credit,
            creditedEntities => {
                map {
                    my ($entities, $total) = $c->model(type_to_model($_))->find_by_artist_credit($artist_credit->id, 10, 0);

                    ("$_" => {
                        count => $total,
                        entities => $entities,
                    })
                } entities_with('artist_credits')
            },
        },

    );
}

map {
    my $entity_type = $_;
    my $entity_properties = $ENTITIES{$entity_type};
    my $url = $entity_properties->{url};

    my $method = sub {
        my ($self, $c) = @_;

        my $artist_credit = $c->stash->{artist_credit};

        my $entities = $self->_load_paged($c, sub {
            $c->model($entity_properties->{model})->find_by_artist_credit($artist_credit->id, shift, shift);
        });

        $c->stash(
            current_view => 'Node',
            component_path => 'artist_credit/EntityList',
            component_props => {
                %{$c->stash->{component_props}},
                entities => $entities,
                entityType => $entity_type,
                page => "/$url",
                pager => serialize_pager($c->stash->{pager}),
                artistCredit => $artist_credit,
            },
        );
    };

    find_meta(__PACKAGE__)->add_method($_ => $method);
    find_meta(__PACKAGE__)->register_method_attributes($method, ["Chained('load')", "PathPart('$url')"]);
} entities_with('artist_credits');

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 MetaBrainz Foundation

This file is part of MusicBrainz, the open internet music database,
and is licensed under the GPL version 2, or (at your option) any
later version: http://www.gnu.org/licenses/gpl-2.0.txt

=cut

