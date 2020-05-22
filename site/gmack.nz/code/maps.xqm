module namespace maps = 'http://gmack.nz/#maps';

(: in memory maps :)

declare 
function maps:myCard(){ 
map {
  'type'  : 'card',
  'name'  : 'Grant MacKenzie',
  'url'   : 'https://gmack.nz',
  'uuid'  : 'https://gmack.nz',
  'email' : 'mailto:grantmacken@gmail.com',
  'note'  : 'somewhere over the rainbow',
  'logo'  : '/icons/user',
  'photo' : 'https://s.gravatar.com/avatar/0650d3fbdb61ed5d8709eda6b80c3e47',
  'nickname' : 'grantmacken',
  'adr' : map {
    'street-address' : '8 Featon Ave',
    'locality' : 'Awhitu',
    'country-name' : 'New Zealand'
    }
  }
};
