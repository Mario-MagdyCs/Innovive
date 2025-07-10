const badgeMaterials = [
    'aluminum_food_can', 'aluminum_soda_can', 'cardboard', 'fabric',
    'glass_bottle', 'glass_jar', 'paper', 'plain_cup',
    'plastic_bag', 'plastic_bottle', 'plastic_cup', 'plastic_cutlery',
    'plastic_detergent_bottle', 'plastic_food_container', 'plastic_straws', 'styrofoam_food_containers'
  ];
  
  const formatTitle = (id) =>
    id.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
  
  module.exports = badgeMaterials.map(material => ({
    id: `${material}_badge`,
    name: formatTitle(material),
    description: `Shared 20 projects using ${material.replace(/_/g, ' ')}`,
    image: `/images/badges/${material}.png`, // You can adjust path based on your folder
    criteria: (user) => {
      const count = user.materialCounts?.[material] || 0;
      const progress = Math.min((count / 10) * 100, 100);
      return {
        earned: count >= 10,
        progress
      };
    }
  }));
  