<?php

namespace App\Entity;

use ApiPlatform\Metadata\Get;
use Doctrine\DBAL\Types\Types;
use ApiPlatform\Metadata\Patch;
use Doctrine\ORM\Mapping as ORM;
use ApiPlatform\Metadata\ApiResource;
use App\Repository\ClientInfoRepository;
use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Validator\Constraints as Assert;

#[ApiResource]
#[Get(
    security: "is_granted('ROLE_ADMIN') or object.getClient() == user",
    normalizationContext: [
        'groups' => ["client_info_get"]
    ],
)]
#[Patch(
    security: "is_granted('ROLE_ADMIN') or object.getClient() === user",
    normalizationContext: [
        'groups' => ["client_info_get"]
    ],
    denormalizationContext: [
        'groups' => ["client_info_patch"]
    ]
)]
#[ORM\Entity(repositoryClass: ClientInfoRepository::class)]
class ClientInfo
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column()]
    #[Groups(["client_info_get", "specific_client_get", "user_register", 'user_get', "project_full_get"])]
    private ?int $id = null;

    #[ORM\Column(length: 255, nullable: true)]
    #[Groups(["client_info_get", "client_info_patch", "specific_client_get", 'user_get', "project_full_get"])]
    private ?string $address = null;

    #[ORM\Column(length: 255, nullable: true)]
    #[Groups(["client_info_get", "client_info_patch", "specific_client_get", 'user_get', "project_full_get"])]
    private ?string $city = null;

    #[ORM\Column(length: 12, nullable: true)]
    #[Assert\Regex(pattern: "/^[0-9]{10}$/")]
    #[Groups(["client_info_get", "client_info_patch", "specific_client_get", 'user_get', "project_full_get"])]
    private ?string $phoneNb = null;

    #[ORM\Column(type: Types::TEXT, nullable: true)]
    #[Groups(["client_info_get", "client_info_patch", "specific_client_get", 'user_get', "project_full_get"])]
    private ?string $description = null;

    #[ORM\OneToOne(inversedBy: 'clientInfo', cascade: ['persist', 'remove'])]
    #[ORM\JoinColumn(nullable: false)]
    #[Groups(["client_info_get"])]
    private ?User $client = null;

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getAddress(): ?string
    {
        return $this->address;
    }

    public function setAddress(string $address): self
    {
        $this->address = $address;

        return $this;
    }

    public function getCity(): ?string
    {
        return $this->city;
    }

    public function setCity(string $city): self
    {
        $this->city = $city;

        return $this;
    }

    public function getPhoneNb(): ?string
    {
        return $this->phoneNb;
    }

    public function setPhoneNb(string $phoneNb): self
    {
        $this->phoneNb = $phoneNb;

        return $this;
    }

    public function getDescription(): ?string
    {
        return $this->description;
    }

    public function setDescription(?string $description): self
    {
        $this->description = $description;

        return $this;
    }

    public function getClient(): ?User
    {
        return $this->client;
    }

    public function setClient(User $client): self
    {
        $this->client = $client;

        return $this;
    }
}
